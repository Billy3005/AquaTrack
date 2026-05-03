from app.crud.base import CRUDBase
from app.models.intake_log import IntakeLog
from app.schemas.intake_log import IntakeLogCreate, IntakeLogUpdate


class CRUDIntakeLog(CRUDBase[IntakeLog, IntakeLogCreate, IntakeLogUpdate]):
    """CRUD operations for IntakeLog model"""

    pass


# Global instance
intake_log_crud = CRUDIntakeLog(IntakeLog)
