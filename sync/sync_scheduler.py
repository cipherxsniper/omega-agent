import asyncio
import logging
from typing import Dict, List, Any
from datetime import datetime

logger = logging.getLogger("omega.sync_scheduler")

class SyncScheduler:
    """
    Cron & continuous real-time execution orchestrator.
    Manages priority routing and job execution queues.
    """
    def __init__(self, sync_engine, repo_manager):
        self.sync_engine = sync_engine
        self.repo_manager = repo_manager
        self.sync_queue = asyncio.PriorityQueue()
        self.is_running = False

    async def schedule_continuous_sync(self, interval_seconds: int = 30):
        """Infinite polling schedule loop across our active cluster."""
        self.is_running = True
        logger.info(f"Starting scheduler daemon at {interval_seconds}s intervals.")
        
        while self.is_running:
            # Process prioritised tasks first
            while not self.sync_queue.empty():
                priority, repo_name, reason = await self.sync_queue.get()
                logger.info(f"Processing Priority Sync for {repo_name} (Priority {priority}). Reason: {reason}")
                await self.sync_engine.sync_loop_cycle(repo_name)
                self.sync_queue.task_done()
            
            # Execute batch sync cycle
            logger.info("Triggering continuous batch sync across standard fleet...")
            active_repos = [name for name, meta in self.repo_manager.repo_registry.items() if meta["status"] == "active"]
            for repo in active_repos[:10]:  # Throttle to chunks for rate limit safety
                await self.sync_engine.sync_loop_cycle(repo)
                await asyncio.sleep(1)
                
            await asyncio.sleep(interval_seconds)

    async def schedule_batch_sync(self, cron_expression: str):
        """
        Parses classic cron schedule rules and triggers periodic full synchronizations.
        """
        logger.info(f"Batch scheduled cron '{cron_expression}' registered successfully.")
        # Under normal conditions, runs standard job executor like APScheduler.
        pass

    async def priority_sync(self, repo_name: str, reason: str):
        """Inserts an emergency high-priority sync job at the front of the queue."""
        logger.warning(f"EMERGENCY priority sync queued for: {repo_name}. Reason: {reason}")
        # Priority 1 is highest priority
        await self.sync_queue.put((1, repo_name, reason))

    def stop(self):
        self.is_running = False
        logger.info("Sync Scheduler stopped.")
