from pandera import SchemaModel
from pandera.typing import Index, Series, DataFrame


class _InputDataScenEcoEquityDF_schema(SchemaModel):
    id_sim: Index[int]
    year_0: Series[float]
    year_1: Series[float]
    year_2: Series[float]
    year_3: Series[float]
    measure: Series[str]  # FIXME

    class Config:
        strict = True
        coerce = True


InputDataScenEcoEquityDF=DataFrame[_InputDataScenEcoEquityDF_schema]

BEGIN_YEAR_POS = 0  # FIXME
