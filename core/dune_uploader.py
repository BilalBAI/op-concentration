import dotenv
import os
from dune_client.client import DuneClient

# change the current working directory where .env file lives
os.chdir("/Users/bilalbai/Documents/Git/op-concentration/")
# load .env file
dotenv.load_dotenv(".env")
# setup Dune Python client
dune = DuneClient.from_env()

# define path to your CSV file
csv_file_path = 'data/test.csv'

with open(csv_file_path) as open_file:
    data = open_file.read()

    table = dune.upload_csv(
        data=str(data),
        description="Measuring the Concentration of Power in the Collective",
        table_name="concentration",
        is_private=False
    )
