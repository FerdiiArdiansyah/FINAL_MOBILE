importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "AIzaSyCEAwDlJ56tRiK_S6yNhR5LBNImXH0JrAA",
  authDomain: "edutech-smk-app-99a83.firebaseapp.com",
  projectId: "edutech-smk-app-99a83",
  storageBucket: "edutech-smk-app-99a83.firebasestorage.app",
  messagingSenderId: "307773262208",
  appId: "1:307773262208:web:3653b0bf88ad33b76a9965",
  measurementId: "G-J95JCL7SJD"
});

const messaging = firebase.messaging();

// Background message handler
messaging.onBackgroundMessage((payload) => {
  const { title, body, icon } = payload.notification ?? {};
  self.registration.showNotification(title ?? "EduTech SMK", {
    body: body ?? "",
    icon: icon ?? "/icons/Icon-192.png",
    badge: "/icons/Icon-192.png",
    data: payload.data,
  });
});
