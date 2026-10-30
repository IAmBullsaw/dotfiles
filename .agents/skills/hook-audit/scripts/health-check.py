#!/usr/bin/env python3
"""
Basic health check for execution architecture
"""
import json
from datetime import datetime, timezone, timedelta
from pathlib import Path

def health_check():
    events_path = Path.home() / ".kiro/logs/events.ndjson"
    if not events_path.exists():
        return {"status": "ERROR", "message": "No events.ndjson found"}
    
    # Get recent events (last hour)
    now = datetime.now(timezone.utc)
    hour_ago = now - timedelta(hours=1)
    
    recent_events = []
    with open(events_path) as f:
        for line in f:
            try:
                event = json.loads(line.strip())
                event_time = datetime.fromisoformat(event.get("timestamp", "").replace('Z', '+00:00'))
                if event_time >= hour_ago:
                    recent_events.append(event)
            except (json.JSONDecodeError, ValueError):
                continue
    
    # Health metrics
    total_recent = len(recent_events)
    wu_unknown_rate = sum(1 for e in recent_events 
                         if e.get("work_unit") and e.get("work_unit").get("id") == "WU-UNKNOWN") / max(total_recent, 1) * 100
    
    correlation_rate = sum(1 for e in recent_events 
                          if e.get("correlation_id")) / max(total_recent, 1) * 100
    
    # Success rate for recent tool calls
    tool_results = [e for e in recent_events if e.get("result", {}).get("success") is not None]
    success_rate = sum(1 for e in tool_results if e.get("result", {}).get("success")) / max(len(tool_results), 1) * 100
    
    # Determine health status
    issues = []
    if total_recent == 0:
        issues.append("No recent activity (last hour)")
    if wu_unknown_rate > 80:
        issues.append(f"High WU-UNKNOWN rate: {wu_unknown_rate:.1f}%")
    if correlation_rate < 50 and total_recent > 10:
        issues.append(f"Low correlation coverage: {correlation_rate:.1f}%")
    if success_rate < 90 and len(tool_results) > 5:
        issues.append(f"Low success rate: {success_rate:.1f}%")
    
    status = "ERROR" if len(issues) > 2 else "WARN" if issues else "OK"
    
    return {
        "status": status,
        "timestamp": now.isoformat(),
        "recent_events": total_recent,
        "wu_unknown_rate": f"{wu_unknown_rate:.1f}%",
        "correlation_rate": f"{correlation_rate:.1f}%", 
        "success_rate": f"{success_rate:.1f}%",
        "issues": issues
    }

def main():
    health = health_check()
    
    print(f"Status: {health['status']}")
    print(f"Recent Events: {health['recent_events']}")
    print(f"WU-UNKNOWN Rate: {health['wu_unknown_rate']}")
    print(f"Correlation Rate: {health['correlation_rate']}")
    print(f"Success Rate: {health['success_rate']}")
    
    if health['issues']:
        print("\nIssues:")
        for issue in health['issues']:
            print(f"- {issue}")

if __name__ == "__main__":
    main()