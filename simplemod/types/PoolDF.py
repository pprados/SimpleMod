from pandera import SchemaModel
from pandera.typing import Series, DataFrame


class _PoolDF_schema(SchemaModel):
    id_sim: Series[int]
    id_pool: Series[int]
    math_res_opening: Series[float]
    math_res_bef_ps: Series[float]
    math_res_closing: Series[float]

    class Config:
        strict = True
        coerce = True


PoolDF = DataFrame[_PoolDF_schema]
PoolInfoClosing = DataFrame[_PoolDF_schema]
PoolInfoOpening = DataFrame[_PoolDF_schema]
PoolInfoBefPs = DataFrame[_PoolDF_schema]


class _PoolPsRatesWithSpread_schema(_PoolDF_schema):
    spread: Series[float]
    class Config:
        strict = True
        coerce = True


PoolPsRatesWithSpread = DataFrame[_PoolPsRatesWithSpread_schema]


class _PoolPsRates_schema(_PoolDF_schema):
    ps_rate: Series[float]
    class Config:
        strict = True
        coerce = True


PoolPsRates = DataFrame[_PoolPsRates_schema]
