import asyncio
import logging
import time
from typing import Dict, Any, List, Optional
from dataclasses import dataclass, field

logger = logging.getLogger("OmegaPerception")

@dataclass
class WorldState:
    timestamp: float
    inputs: Dict[str, Any] = field(default_factory=dict)
    anomalies: List[Dict[str, Any]] = field(default_factory=list)
    system_load: float = 0.0
    network_latency: float = 0.0
    active_connections: int = 0

class AnomalyDetector:
    """
    Computes statistical and structural deviation patterns on system inputs.
    """
    def __init__(self, deviation_threshold: float = 2.0):
        self.deviation_threshold = deviation_threshold
        self.metric_history: Dict[str, List[float]] = {}

    def observe_metric(self, name: str, value: float) -> Optional[Dict[str, Any]]:
        """
        Record a numerical observation and check if it deviates from rolling history.
        """
        if name not in self.metric_history:
            self.metric_history[name] = []
        
        history = self.metric_history[name]
        history.append(value)
        
        # Keep sliding window of last 50 observations
        if len(history) > 50:
            history.pop(0)
            
        if len(history) < 10:
            return None  # Insufficient baseline data
            
        # Compute mean and standard deviation
        mean = sum(history) / len(history)
        variance = sum((x - mean) ** 2 for x in history) / len(history)
        std_dev = variance ** 0.5
        
        if std_dev == 0:
            return None
            
        z_score = abs(value - mean) / std_dev
        if z_score > self.deviation_threshold:
            anomaly = {
                "metric": name,
                "current_value": value,
                "mean": mean,
                "z_score": z_score,
                "timestamp": time.time(),
                "severity": "HIGH" if z_score > 3.5 else "MEDIUM"
            }
            logger.warning(f"ANOMALY DETECTED: {anomaly}")
            return anomaly
            
        return None


class Contextualizer:
    """
    Consolidates disparate data modalities into a single continuous unified WorldState.
    """
    def __init__(self):
        self.current_state: WorldState = WorldState(timestamp=time.time())

    def update_state(self, updates: Dict[str, Any], anomalies: List[Dict[str, Any]] = None) -> WorldState:
        self.current_state.timestamp = time.time()
        self.current_state.inputs.update(updates)
        if anomalies:
            self.current_state.anomalies.extend(anomalies)
            # Cap anomaly history
            self.current_state.anomalies = self.current_state.anomalies[-20:]
            
        # Parse standard system-load indicators if present
        if "system_load" in updates:
            self.current_state.system_load = updates["system_load"]
        if "network_latency" in updates:
            self.current_state.network_latency = updates["network_latency"]
        if "active_connections" in updates:
            self.current_state.active_connections = updates["active_connections"]
            
        return self.current_state


class MultiModalPerception:
    """
    Normalizes text streams, binary files, structured JSON data, and API responses.
    """
    def __init__(self):
        self.contextualizer = Contextualizer()
        self.anomaly_detector = AnomalyDetector()

    async def ingest(self, modality_type: str, data: Any) -> WorldState:
        """
        Accepts any incoming data type, normalizes it, runs anomaly detection,
        and pushes it to the WorldState contextualizer.
        """
        normalized_data: Dict[str, Any] = {}
        detected_anomalies: List[Dict[str, Any]] = []
        
        logger.info(f"Ingesting {modality_type} data stream...")

        if modality_type == "text":
            normalized_data = {
                "raw_text": str(data),
                "length": len(str(data)),
                "ingest_type": "text"
            }
        elif modality_type == "structured":
            if isinstance(data, dict):
                normalized_data = data
            else:
                normalized_data = {"raw_payload": str(data)}
            normalized_data["ingest_type"] = "structured"
            
            # Check numerical fields in structured inputs for anomalies
            for k, v in normalized_data.items():
                if isinstance(v, (int, float)):
                    anomaly = self.anomaly_detector.observe_metric(k, float(v))
                    if anomaly:
                        detected_anomalies.append(anomaly)
                        
        elif modality_type == "api_response":
            normalized_data = {
                "status_code": data.get("status_code", 200) if isinstance(data, dict) else 200,
                "payload": data,
                "ingest_type": "api"
            }
            # Track API latency if provided
            if isinstance(data, dict) and "latency_ms" in data:
                anomaly = self.anomaly_detector.observe_metric("api_latency", float(data["latency_ms"]))
                if anomaly:
                    detected_anomalies.append(anomaly)
        else:
            normalized_data = {
                "raw_bytes_len": len(bytes(data)) if hasattr(data, "__bytes__") else 0,
                "ingest_type": "binary"
            }

        # Update integrated world state representation
        state = self.contextualizer.update_state(normalized_data, detected_anomalies)
        return state


class RealTimeMonitor:
    """
    Asynchronous continuous background monitor watching system metrics.
    """
    def __init__(self, perception_layer: MultiModalPerception, polling_interval: float = 2.0):
        self.perception = perception_layer
        self.polling_interval = polling_interval
        self.is_running = False
        self._task: Optional[asyncio.Task] = None

    async def start(self):
        self.is_running = True
        self._task = asyncio.create_task(self._monitor_loop())
        logger.info("RealTimeMonitor started successfully.")

    async def stop(self):
        self.is_running = False
        if self._task:
            self._task.cancel()
            try:
                await self._task
            except asyncio.CancelledError:
                pass
        logger.info("RealTimeMonitor stopped.")

    async def _monitor_loop(self):
        while self.is_running:
            try:
                # Simulate capturing local infrastructure states
                simulated_metrics = {
                    "system_load": 0.45,
                    "network_latency": 12.5,
                    "active_connections": 5,
                    "timestamp": time.time()
                }
                # Inject performance metrics directly into perception
                await self.perception.ingest("structured", simulated_metrics)
            except Exception as e:
                logger.error(f"Error in continuous monitor loop: {e}", exc_info=True)
            await asyncio.sleep(self.polling_interval)
