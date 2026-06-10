from app.crud.base import CRUDBase
from app.models.achievement import Achievement


class CRUDAchievement(CRUDBase[Achievement, dict, dict]):
    """CRUD operations for Achievement model"""


# Global instance
achievement_crud = CRUDAchievement(Achievement)
