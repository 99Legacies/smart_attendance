"use strict";

const crypto = require("crypto");
const admin = require("firebase-admin");
const {onCall, HttpsError} = require("firebase-functions/v2/https");

admin.initializeApp();

const db = admin.firestore();
const FieldValue = admin.firestore.FieldValue;
const Timestamp = admin.firestore.Timestamp;

const SESSION_STALE_AFTER_MS = 12 * 60 * 60 * 1000;
const SWAP_DOC_TTL_MS = 15 * 60 * 1000;

function requireUid(request) {
  const uid = request.auth && request.auth.uid;
  if (!uid) {
    throw new HttpsError(
      "unauthenticated",
      "You must be signed in before changing session state.",
    );
  }
  return uid;
}

function sanitizeDeviceId(value) {
  if (typeof value !== "string") {
    throw new HttpsError("invalid-argument", "deviceId must be a string.");
  }

  const deviceId = value.trim();
  if (deviceId.length < 8 || deviceId.length > 256) {
    throw new HttpsError(
      "invalid-argument",
      "deviceId must be between 8 and 256 characters.",
    );
  }
  return deviceId;
}

function sessionToken() {
  return crypto.randomBytes(32).toString("hex");
}

function isStaleSession(data, nowMs) {
  const updatedAt = data.sessionUpdatedAt;
  if (!updatedAt || typeof updatedAt.toMillis !== "function") return true;
  return nowMs - updatedAt.toMillis() > SESSION_STALE_AFTER_MS;
}

function publicUserPayload(data) {
  return {
    role: typeof data.role === "string" ? data.role : "student",
  };
}

function tokenPreview(token) {
  return `${token.substring(0, 8)}...${token.substring(token.length - 6)}`;
}

exports.bindSession = onCall({region: "us-central1"}, async (request) => {
  const uid = requireUid(request);
  const deviceId = sanitizeDeviceId(request.data && request.data.deviceId);
  const userRef = db.collection("users").doc(uid);
  const token = sessionToken();
  const nowMs = Date.now();

  console.log("bindSession:start", {uid, deviceId});

  const result = await db.runTransaction(async (tx) => {
    const snap = await tx.get(userRef);
    if (!snap.exists) {
      throw new HttpsError("not-found", "User profile was not found.");
    }

    const data = snap.data() || {};
    const activeDeviceId =
      typeof data.activeDeviceId === "string" ? data.activeDeviceId : "";
    const canBind =
      activeDeviceId.length === 0 ||
      activeDeviceId === deviceId ||
      isStaleSession(data, nowMs);

    if (!canBind) {
      console.warn("bindSession:conflict", {
        uid,
        requestedDeviceId: deviceId,
        activeDeviceId,
      });
      throw new HttpsError(
        "failed-precondition",
        "Your account is already active on another device.",
        {existingDeviceId: activeDeviceId},
      );
    }

    tx.update(userRef, {
      activeDeviceId: deviceId,
      activeSessionToken: token,
      sessionUpdatedAt: FieldValue.serverTimestamp(),
      sessionState: "active",
    });

    return publicUserPayload(data);
  });

  console.log("bindSession:success", {
    uid,
    deviceId,
    sessionTokenPreview: tokenPreview(token),
  });

  return {
    status: "bound",
    sessionToken: token,
    deviceId,
    role: result.role,
  };
});

exports.overrideSession = onCall({region: "us-central1"}, async (request) => {
  const uid = requireUid(request);
  const requestedUserId =
    typeof (request.data && request.data.userId) === "string"
      ? request.data.userId.trim()
      : uid;
  if (requestedUserId !== uid) {
    throw new HttpsError(
      "permission-denied",
      "You can only override your own session.",
    );
  }

  const deviceId = sanitizeDeviceId(
    (request.data && (request.data.newDeviceId || request.data.deviceId)),
  );
  const userRef = db.collection("users").doc(uid);
  const swapRef = userRef.collection("sessionSwaps").doc();
  const token = sessionToken();
  const expiresAt = Timestamp.fromMillis(Date.now() + SWAP_DOC_TTL_MS);

  console.log("overrideSession:start", {uid, newDeviceId: deviceId});

  const result = await db.runTransaction(async (tx) => {
    const snap = await tx.get(userRef);
    if (!snap.exists) {
      throw new HttpsError("not-found", "User profile was not found.");
    }

    const data = snap.data() || {};
    const previousDeviceId =
      typeof data.activeDeviceId === "string" ? data.activeDeviceId : "";
    const previousSessionToken =
      typeof data.activeSessionToken === "string"
        ? data.activeSessionToken
        : "";

    console.log("overrideSession:transaction:update", {
      uid,
      previousDeviceId,
      newDeviceId: deviceId,
      previousTokenPreview: previousSessionToken
        ? tokenPreview(previousSessionToken)
        : "",
      newTokenPreview: tokenPreview(token),
    });

    tx.update(userRef, {
      activeDeviceId: deviceId,
      activeSessionToken: token,
      sessionUpdatedAt: FieldValue.serverTimestamp(),
      sessionState: "active",
    });

    tx.set(swapRef, {
      status: "completed",
      uid,
      previousDeviceId,
      previousSessionTokenHash: previousSessionToken
        ? crypto.createHash("sha256").update(previousSessionToken).digest("hex")
        : "",
      newDeviceId: deviceId,
      createdAt: FieldValue.serverTimestamp(),
      completedAt: FieldValue.serverTimestamp(),
      expiresAt,
      reason: "user_confirmed_device_override",
    });

    tx.set(db.collection("security_logs").doc(), {
      uid,
      type: "session_swap",
      status: "completed",
      previousDeviceId,
      newDeviceId: deviceId,
      createdAt: FieldValue.serverTimestamp(),
    });

    return publicUserPayload(data);
  });

  console.log("overrideSession:success", {
    uid,
    swapId: swapRef.id,
    newDeviceId: deviceId,
    sessionTokenPreview: tokenPreview(token),
  });

  return {
    status: "completed",
    swapId: swapRef.id,
    sessionToken: token,
    deviceId,
    role: result.role,
  };
});

exports.requestSessionSwap = exports.overrideSession;

exports.releaseSession = onCall({region: "us-central1"}, async (request) => {
  const uid = requireUid(request);
  const deviceId = sanitizeDeviceId(request.data && request.data.deviceId);
  const userRef = db.collection("users").doc(uid);

  await db.runTransaction(async (tx) => {
    const snap = await tx.get(userRef);
    if (!snap.exists) return;

    const data = snap.data() || {};
    const activeDeviceId =
      typeof data.activeDeviceId === "string" ? data.activeDeviceId : "";
    if (activeDeviceId !== deviceId) return;

    tx.update(userRef, {
      activeDeviceId: "",
      activeSessionToken: "",
      sessionUpdatedAt: FieldValue.serverTimestamp(),
      sessionState: "signed_out",
    });

    tx.set(db.collection("security_logs").doc(), {
      uid,
      type: "session_release",
      status: "completed",
      deviceId,
      createdAt: FieldValue.serverTimestamp(),
    });
  });

  return {status: "released"};
});
