import asyncio
from concurrent.futures import ThreadPoolExecutor

def run_in_threadpool(func, *args, **kwargs):
    loop = asyncio.get_event_loop()
    executor = ThreadPoolExecutor()
    return loop.run_in_executor(executor, func, *args, **kwargs)

async def async_heavy_task(data):
    await asyncio.sleep(1)  # 예시: 실제로는 대용량 연산/IO
    return f"Processed {data}" 