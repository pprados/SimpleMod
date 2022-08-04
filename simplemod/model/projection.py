from typing import Tuple

from .formulas import *


def init_model() -> Tuple[InputDataPol, InputDataPool]:
    # FIXME need to be changed when simulation is added to pol_data.index
    # FIXME : quickfix, but it would be better if we can broadcast the asignement along the axis (may be easier once we have xarrays)
    # pol_data["id_pol"] = input_data_pol.index.to_list() * nb_sim  # FIXME
    # # FIXME need to be changed when simulation is added to pool_data.index
    # # FIXME : quickfix, but it would be better if we can broadcast the asignement along the axis (may be easier once we have xarrays)
    # pool_data["id_pool"] = input_data_pool.index.to_list() * nb_sim  # FIXME
    return None, None


@delayed
@check_types
def one_year(
        input_data_pol: InputDataPol,
        input_data_pool: InputDataPool,
        input_data_scen_eco_equity: InputDataScenEcoEquityDF,
        pol_data: PolDF,
        pool_data: PoolDF,
        year: int,
        nb_sim: int
) -> Tuple[PoolInfoClosing, PolInfoClosing]:
    # FIXME: implement one_year
    # Initialisation
    # if year == 0:
    #     # FIXME need to be changed when simulation is added to pol_data.index
    #     # FIXME : quickfix, but it would be better if we can broadcast the asignement along the axis (may be easier once we have xarrays)
    #     pol_data["id_pol"] = input_data_pol.index.to_list() * nb_sim  # FIXME
    #     # FIXME need to be changed when simulation is added to pool_data.index
    #     # FIXME : quickfix, but it would be better if we can broadcast the asignement along the axis (may be easier once we have xarrays)
    #     pool_data["id_pool"] = input_data_pool.index.to_list() * nb_sim  # FIXME

    pol_data: PolInfoOpening = pol_opening(
        input_data_pol, pol_data, year, nb_sim)
    # NOTE: la sauvegarde à chaque étape est contre productif au niveau performance

    pol_data: PolInfoBefPs = pol_bef_ps(pol_data, year)  # FIXME: réutiliser la même variable n'est pas correct

    pool_data: PoolInfoBefPs = pool_bef_ps(pol_data, pool_data)

    pool_data: PoolPsRates = pool_ps(input_data_scen_eco_equity,
                                     input_data_pool, pool_data, year, nb_sim)

    pol_data: PolInfoClosing = pol_aft_ps(pol_data, pool_data, year)

    pool_data: PoolInfoClosing = pool_closing(pol_data, pool_data, year)

    pool_data: PoolInfoOpening = pool_opening(pool_data, pol_data, year)

    return pol_data, pool_data


def projection(input_data_pol: InputDataPol,
               input_data_pool: InputDataPool,
               input_data_scen_eco_equity: InputDataScenEcoEquityDF) -> None:
    nb_scenarios = 3
    nb_years = 3
    pol_data, pool_data = init_model()
    for year in range(nb_years):
        print(f"--> year: {year}")
        pol_data, pool_data = one_year(
            input_data_pol,
            input_data_pool,
            input_data_scen_eco_equity,
            pol_data,
            pool_data,
            year,
            nb_scenarios
        )
        # TODO: result must be input
