"""Smoke test: connect to PX4 SITL, take off to 5 m, hover, land.
Run inside the container while `sim` is running:  python3 ~/code/takeoff_land.py

Uses the native MAVSDK API (mavsdk>=4), not the old gRPC one (mavsdk<4).
"""
import asyncio

from mavsdk.asyncio import ComponentType, Configuration, Mavsdk
from mavsdk.asyncio.plugins.action import ActionAsync
from mavsdk.asyncio.plugins.telemetry import TelemetryAsync


async def main():
    config = Configuration.create_with_component_type(ComponentType.GROUND_STATION)
    async with Mavsdk(config) as mavsdk:
        await mavsdk.add_any_connection("udpin://0.0.0.0:14540")

        print("Waiting for drone to connect...")
        system = await mavsdk.first_autopilot(timeout_s=30.0)
        if system is None:
            raise SystemExit("No autopilot found on UDP 14540. Is `sim` running?")
        print("Connected")

        action = ActionAsync(system)
        telemetry = TelemetryAsync(system)

        print("Waiting for global position / home position...")
        async for health in telemetry.subscribe_health():
            if health.is_global_position_ok and health.is_home_position_ok:
                print("Position OK")
                break

        await action.set_takeoff_altitude(5.0)
        print("Arming")
        await action.arm()
        print("Taking off")
        await action.takeoff()
        await asyncio.sleep(10)

        print("Landing")
        await action.land()
        async for in_air in telemetry.subscribe_in_air():
            if not in_air:
                print("Landed")
                break


if __name__ == "__main__":
    asyncio.run(main())
