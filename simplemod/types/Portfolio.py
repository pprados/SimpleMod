from pandera import SchemaModel
from pandera.typing import Series, DataFrame, Index


class _Portfolio_schema(SchemaModel):
    id: Index[int]
    id_policy: Series[int]
    id_pool: Series[int]
    Age: Series[int]
    math_res: Series[int]
    spread: Series[float]

    class Config:
        strict = True
        coerce = True


Portfolio = DataFrame[_Portfolio_schema]
