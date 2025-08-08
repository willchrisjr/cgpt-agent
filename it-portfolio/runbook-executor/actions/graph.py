from typing import Any, Dict


def ensure_user_is_disabled(payload: Dict[str, Any]) -> str:
    """Placeholder for a Microsoft Graph action that disables a user.

    Returns a string status for now.
    """
    user_id = payload.get("user_id", "unknown")
    return f"simulated:disabled:{user_id}"