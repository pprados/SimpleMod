from simplemod.types import *
from simplemod.model import pol_bef_ps, pol_aft_ps, pool_closing, pool_opening, pol_opening, pool_ps, pool_bef_ps
from virtual_dataframe import VDataFrame, compute
from pandera.typing import Index, Series, DataFrame


def test_pol_bef_ps() -> None:
    # With
    input_pol_data: PolDF = VDataFrame(
        {
            "id_sim": [0],
            "id_pol": [0],
            "id_pool": [0],
            "math_res_opening": [0.0],
            "math_res_bef_ps": [0.0],
            "math_res_closing": [0.0],
        }
    )
    expected: PolInfoBefPs = VDataFrame(
        {
            "id_sim": [0],
            "id_pol": [0],
            "id_pool": [0],
            "math_res_opening": [0.0],
            "math_res_bef_ps": [0.0],
            "math_res_closing": [0.0],
        }
    )

    # When
    result = pol_bef_ps(input_pol_data, year=0)

    # Then
    expected, result = compute(expected, result)
    assert expected.equals(result)


def test_pol_aft_ps() -> None:
    # With
    input_pol_data: PolInfoBefPs = VDataFrame(
        {
            "id_sim": [0],
            "id_pol": [0],
            "id_pool": [0],
            "math_res_opening": [0.0],
            "math_res_bef_ps": [0.0],
            "math_res_closing": [0.0],
        }
    )

    input_pool_ps_rates: PoolPsRates = VDataFrame(
        {
            "id_sim": [0],
            "id_pool": [0],
            "math_res_opening": [0.0],
            "math_res_bef_ps": [0.0],
            "math_res_closing": [0.0],
            "ps_rate": [0.0]
        }
    )
    expected: PolInfoClosing = VDataFrame(
        {
            "id_sim": [0],
            "id_pol": [0],
            "id_pool": [0],
            "math_res_opening": [0.0],
            "math_res_bef_ps": [0.0],
            "math_res_closing": [0.0],
        }
    )

    # When
    result = pol_aft_ps(input_pol_data, input_pool_ps_rates, year=0)

    # Then
    expected, result = compute(expected, result)
    assert expected.equals(result)


def test_pool_closing() -> None:
    # With
    input_pol_data: PolInfoClosing = VDataFrame(
        {
            "id_sim": [0],
            "id_pol": [0],
            "id_pool": [0],
            "math_res_opening": [0.0],
            "math_res_bef_ps": [0.0],
            "math_res_closing": [0.0],
        }
    )
    input_pool_data: PoolInfoBefPs = VDataFrame(
        {
            "id_sim": [0],
            "id_pool": [0],
            "math_res_opening": [0.0],
            "math_res_bef_ps": [0.0],
            "math_res_closing": [0.0],
        }
    )
    expected: PoolInfoClosing = VDataFrame(
        {
            "id_sim": [0],
            "id_pool": [0],
            "math_res_opening": [0.0],
            "math_res_bef_ps": [0.0],
            "math_res_closing": [0.0],
        }
    )

    # When
    result = pool_closing(input_pol_data, input_pool_data, year=0)

    # Then
    expected, result = compute(expected, result)
    assert expected.equals(result)


def test_pool_opening() -> None:
    # With
    input_pool_data: PoolInfoClosing = VDataFrame(
        {
            "id_sim": [0],
            "id_pool": [0],
            "math_res_opening": [0.0],
            "math_res_bef_ps": [0.0],
            "math_res_closing": [0.0],
        }
    )
    input_pol_data: PolInfoOpening = VDataFrame(
        {
            "id_sim": [0],
            "id_pol": [0],
            "id_pool": [0],
            "math_res_opening": [0.0],
            "math_res_bef_ps": [0.0],
            "math_res_closing": [0.0],
        }
    )
    expected: PoolInfoOpening = VDataFrame(
        {
            "id_sim": [0],
            "id_pool": [0],
            "math_res_opening": [0.0],
            "math_res_bef_ps": [0.0],
            "math_res_closing": [0.0],
        }
    )

    # When
    result = pool_opening(input_pool_data, input_pol_data, year=0)

    # Then
    expected, result = compute(expected, result)
    assert expected.equals(result)


def test_pol_opening() -> None:
    # With
    input_data_pol: InputDataPol = VDataFrame(
        {
            "id_pool": [0],
            "age": [0],
            "math_res": [0.0],
        }
    )
    input_pol_data: PolInfoOpening = VDataFrame(
        {
            "id_sim": [0],
            "id_pol": [0],
            "id_pool": [0],
            "math_res_opening": [0.0],
            "math_res_bef_ps": [0.0],
            "math_res_closing": [0.0],
        }
    )
    expected: PolInfoOpening = VDataFrame(
        {
            "id_sim": [0],
            "id_pol": [0],
            "id_pool": [0],
            "math_res_opening": [0.0],
            "math_res_bef_ps": [0.0],
            "math_res_closing": [0.0],
        }
    )

    # When
    result = pol_opening(input_data_pol, input_pol_data, year=0, nb_sim=1)

    # Then
    expected, result = compute(expected, result)
    assert expected.equals(result)


def test_pool_ps() -> None:
    # With
    input_scen_eco_equity: InputDataScenEcoEquityDF = InputDataScenEcoEquityDF(
        {
            "year_0": [0.0],
            "year_1": [0.0],
            "year_2": [0.0],
            "year_3": [0.0],
            "measure": ["abc"],
        }
    )
    input_data_pool: InputDataPool = InputDataPool(
        {
            "spread": [0.0],
        }
    )
    input_pool_data: PoolPsRatesWithSpread = PoolPsRatesWithSpread(
        {
            "id_sim": [0],
            "id_pool": [0],
            "math_res_opening": [0.0],
            "math_res_bef_ps": [0.0],
            "math_res_closing": [0.0],
            "spread": [0.0],
        }
    )

    expected: PoolPsRates = VDataFrame(
        {
            "id_sim": [0],
            "id_pool": [0],
            "math_res_opening": [0.0],
            "math_res_bef_ps": [0.0],
            "math_res_closing": [0.0],
            "ps_rate": [0.0],
        }
    )

    # When
    result = pool_ps(input_scen_eco_equity,
                     input_data_pool,
                     input_pool_data,
                     year=0,
                     nb_sim=1)

    # Then
    expected, result = compute(expected, result)
    assert expected.equals(result)


def test_pool_bef_ps() -> None:
    # With
    input_pol_data: PolInfoBefPs = VDataFrame(
        {
            "id_sim": [0],
            "id_pol": [0],
            "id_pool": [0],
            "math_res_opening": [0.0],
            "math_res_bef_ps": [0.0],
            "math_res_closing": [0.0],
        }
    )
    input_pool_data: PoolInfoOpening = VDataFrame(
        {
            "id_sim": [0],
            "id_pool": [0],
            "math_res_opening": [0.0],
            "math_res_bef_ps": [0.0],
            "math_res_closing": [0.0],
        }
    )
    expected: PoolInfoBefPs = VDataFrame(
        {
            "id_sim": [0],
            "id_pool": [0],
            "math_res_opening": [0.0],
            "math_res_bef_ps": [0.0],
            "math_res_closing": [0.0],
        }
    )

    # When
    result = pool_bef_ps(input_pol_data, input_pool_data)

    # Then
    expected, result = compute(expected, result)
    assert expected.equals(result)
