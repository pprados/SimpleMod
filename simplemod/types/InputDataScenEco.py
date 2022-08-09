from pandera import SchemaModel
from pandera.typing import Index, Series, DataFrame


class _InputDataScenEcoEquityDF_schema(SchemaModel):
    id_sim: Index[int]
    y0: Series[float]
    y1: Series[float]
    y2: Series[float]
    y3: Series[float]
#    4: Series[float]
#    5: Series[float]
#    6: Series[float]
#    7: Series[float]
#    8: Series[float]
#    9: Series[float]
#    10: Series[float]
    measure: Series[str]  # FIXME

    class Config:
        strict = True
        coerce = True


InputDataScenEcoEquityDF=DataFrame[_InputDataScenEcoEquityDF_schema]

BEGIN_YEAR_POS = 0  # FIXME
