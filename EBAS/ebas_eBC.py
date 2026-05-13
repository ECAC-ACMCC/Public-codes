import threddsclient
import xarray as xr
import pandas as pd
from pathlib import Path
import json
#from igorwriter import IgorWave
#from igorwriter import utils 

CATALOG_URL = "https://thredds.nilu.no/thredds/catalog/actris_nrt/catalog.html"
KEYWORD = "filter_absorption_photometer"

#VAR_ORGANIC = "organic_mass_amean"
# VARIABLES = [
#     "organic_mass_amean",
#     "nitrate_amean",
#     "ammonium_amean",
#     "sulphate_total_amean",
#     "chloride_amean",
# ]
VAR_CANDIDATES = {"eBC": ["equivalent_black_carbon_amean"]}

OUTPUT_DIR = Path(r"D:\Documents\ACTRIS\EBAS\ACSMdata\ebasextraction")

urls = threddsclient.opendap_urls(CATALOG_URL)


STATION_TEST = "FR0020R"
LEVEL="lev3b"

filtered_urls = [
    url for url in urls
    if url.endswith(".nc")
    and KEYWORD in url
    and STATION_TEST in url
    and LEVEL in url
]

print(f"{len(filtered_urls)} fichiers trouvés")

def get_station_name(ds, url):
    filename = url.split("/")[-1]
    
    # station = avant le premier point
    station = filename.split(".")[0]
    
    return station


def get_station_metadata(ds,code) :
    comment_str = ds.attrs["comment"]
    comment_dict = json.loads(comment_str)
    meta = comment_dict[code]
    return meta

def get_var(ds, candidates):
    for var in candidates:
        if var in ds.data_vars:
            return var
    return None

def map_variables(ds):
    mapping = {}

    for key, candidates in VAR_CANDIDATES.items():
        var = get_var(ds, candidates)
        if var:
            mapping[key] = var

    return mapping



station_data = {}


# def save_two_waves(df, filepath):
#     # index → datetime
#     time = pd.to_datetime(df.index)

#     # conversion en secondes depuis epoch
#     time_seconds = (time - pd.Timestamp("1970-01-01")) // pd.Timedelta("1s")

#     organic = df.iloc[:, 0].values

#     # créer les deux waves
#     wave_time = IgorWave(time_seconds, name="ACSMtime")
#     wave_org = IgorWave(organic, name="organic")

#     # ajouter metadata (optionnel mais utile)
#     #wave_time.note = "time in seconds since 1970-01-01"
#     #wave_org.note = "organic aerosol concentration (µg/m3)"

#     # sauvegarde dans le même fichier
#     wave_time.save_itx(filepath)
#     wave_time.set_dimscale('y', 0, 0,'dat')
#     wave_org.save_itx(filepath)
    
    


# url=filtered_urls[0]

# ds = xr.open_dataset(url)
# station = get_station_name(ds, url)

# da = ds[VAR_ORGANIC]

# df = da.to_dataframe().reset_index()
# df = df[["time", VAR_ORGANIC]].dropna()

# df.plot("time",VAR_ORGANIC)

# plt.title(f"Organic aerosol - {station}")
# plt.xlabel("Time")
# plt.ylabel("Concentration")
# plt.grid()
# plt.show()


for url in filtered_urls:
    try:
        print(f"Lecture : {url}")
        ds = xr.open_dataset(url)

        if "time" not in ds:
            continue

        station = get_station_name(ds, url)

        var_map = map_variables(ds)

        if not var_map:
            print("Aucune variable trouvée")
        else:
            df = ds[list(var_map.values())].to_dataframe().reset_index()
            df = df.rename(columns={v: k for k, v in var_map.items()})

        # extraire variable
        #da = ds[VARIABLES]

        # convertir en dataframe
        #df = da.to_dataframe().reset_index()

        # garder seulement time + variable
        #df = df[["time", VARIABLES]].dropna()

        # stocker par station
        if station not in station_data:
            station_data[station] = []

        station_data[station].append(df)
        
        print(get_station_metadata(ds, "Station name"))

    except Exception as e:
        print(f"Erreur : {e}")
        
final_series = {}

for station, dfs in station_data.items():
    combined = pd.concat(dfs, ignore_index=True)

    # nettoyer
    combined = combined.drop_duplicates(subset="time")
    combined = combined.sort_values("time")

    combined = combined.set_index("time")

    final_series[station] = combined

    print(f"{station}: {len(combined)} points")
    

for station, df in final_series.items():
    filename = OUTPUT_DIR / f"{station}_eBC_timeseries.csv"
    df.to_csv(filename)

    print(f"Sauvegardé : {filename}")
    
    
# for station, df in final_series.items():
#     filename = OUTPUT_DIR / f"{station}_acsm_timeseries.itx"
    
#     utils.dataframe_to_itx(df, filename)
    
#     #save_two_waves(df, filename)

#     print(f"Sauvegardé : {filename}")