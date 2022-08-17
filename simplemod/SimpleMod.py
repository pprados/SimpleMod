import sys
from typing import get_args
import dotenv
import click
import pandas as pd
import os
from time import time

from simplemod.constants import SIM_COUNT, POL_COUNT, POOL_COUNT
from simplemod.types import InputDataPol, InputDataPool, InputDataScenEcoEquityDF, PolDF, PoolDF
from simplemod.model import one_year, projection
from simplemod.tools import init_logger, logging
from simplemod.utils import init_vdf_from_schema, schema_to_dtypes
import virtual_dataframe as vdf


LOGGER = logging.getLogger(__name__)
nb_simulations = 10

# %%

@click.command(short_help="Sample for Cardif")
def main() -> int:
    # %%
    input_data_pol = vdf.read_csv(
        "./data/mp_policies*.csv",
        dtype=schema_to_dtypes(InputDataPol, "id_policy"),
    ).set_index("id_policy", drop=True)

    # %%
    input_data_pool = vdf.read_csv(
        "./data/mp_pool*.csv",
        dtype=schema_to_dtypes(InputDataPool, "id_pool")
    ).set_index("id_pool")

    # %%
    input_data_scen_eco_equity = vdf.read_csv(
        "./data/scen_eco_sample*.csv",
        dtype=schema_to_dtypes(InputDataScenEcoEquityDF, "id_sim")
    ).set_index("id_sim").loc[:SIM_COUNT, :]  # FIXME implement read_csv_with_schema / DataFrame_with_schema

    duree = 0
    #print(input_data_scen_eco_equity.head())
    # %% -- projection
    delayed_results = []
    for i in range(0,nb_simulations):

        t_start = time()
        pol_data, pool_data = projection(input_data_pol,
                input_data_pool,
                input_data_scen_eco_equity)
        # pol_data, pool_data = vdf.compute(pol_data,pool_data) 
        delayed_results.append(pol_data.shape)
        t_end = time()
        duree+=t_end-t_start
        print('Computed in {:.04f}s'.format((t_end-t_start)))
    results = vdf.compute(*delayed_results)
    print(results[0])
    print('ALL Computed in {:.04f}s'.format((duree)))
    print('Moyenne ALL Computed in {:.04f}s'.format((duree/nb_simulations)))
            
    return 0


if __name__ == '__main__':
    init_logger(LOGGER, logging.INFO)
    
    # find .env automagically by walking up directories until it's found, then
    # load up the .env entries as environment variables
    # if not hasattr(sys, 'frozen') and hasattr(sys, '_MEIPASS'):
    dotenv.load_dotenv(dotenv.find_dotenv())
    sys.exit(main(standalone_mode=False))  # pylint: disable=no-value-for-parameter,unexpected-keyword-arg
