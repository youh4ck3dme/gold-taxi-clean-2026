# GoldTaxi Future Ops Dashboard

This is an internal planning and diagnostics dashboard for tracking the blueprinting, prototyping, and security stabilization of the GoldTaxi codebase.

It serves as a checkpointing tool to enforce the **STOPKA (STOP) rule**: after every batch of 5 completed items, a mandatory review/audit must be run before starting the next batch.

## How to Run

You can run and access the dashboard in two ways:

### 1. Direct File Access
Simply open the HTML file directly in your web browser:
- Double-click or open: [goldtaxi_future_ops_dashboard.html](file:///Users/erikbabcan/Gold-taxi/ops/goldtaxi_future_ops_dashboard.html)

### 2. Local HTTP Server (Recommended)
To prevent potential CORS or local storage restrictions in some browsers, run a simple local Python server:

```bash
python3 -m http.server 4173 -d ops
```

Then open your browser and navigate to:
[http://localhost:4173/goldtaxi_future_ops_dashboard.html](http://localhost:4173/goldtaxi_future_ops_dashboard.html)
