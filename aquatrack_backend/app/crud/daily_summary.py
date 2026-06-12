from app.crud.base import CRUDBase
from app.models.daily_summary import DailySummary


class CRUDDailySummary(CRUDBase[DailySummary, dict, dict]):
    """CRUD operations for DailySummary model"""


# Global instance
daily_summary_crud = CRUDDailySummary(DailySummary)
