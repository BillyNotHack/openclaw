import WebSocket from "ws";

const ws = new WebSocket("wss://openclaw-production-d0f1.up.railway.app");
const token = "ed98289f-75e2-43d3-bad9-b73156448cd6";

ws.on("open", () => {
  console.log("Connected, waiting for challenge...");
});

ws.on("message", (data) => {
  const msg = JSON.parse(data.toString());
  console.log("Received:", JSON.stringify(msg, null, 2));

  if (msg.event === "connect.challenge") {
    // Respond to challenge with connect request
    const connectReq = {
      id: "test-1",
      method: "connect",
      params: {
        auth: { token: token },
        client: { name: "test-client", mode: "cli" }
      }
    };
    console.log("Sending connect with token:", token);
    ws.send(JSON.stringify(connectReq));
  } else if (msg.id === "test-1") {
    console.log("Connect response received!");
    if (msg.error) {
      console.log("ERROR:", msg.error);
    } else {
      console.log("SUCCESS!");
    }
    ws.close();
    process.exit(msg.error ? 1 : 0);
  }
});

ws.on("error", (err) => {
  console.error("Error:", err.message);
  process.exit(1);
});

ws.on("close", (code, reason) => {
  console.log("Closed:", code, reason.toString());
});

setTimeout(() => {
  console.log("Timeout");
  process.exit(1);
}, 10000);
