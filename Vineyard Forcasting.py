# -*- coding: utf-8 -*-
"""
Created on Wed Oct 25 23:11:24 2023

@author: cian3
"""
import pandas as pd
from urllib.request import urlretrieve
from requests import get

#Display Entire DataFrame
pd.set_option('display.max_rows', None)
pd.set_option('display.max_columns', None) 

vineyards = pd.read_csv(r"C:\Users\cian3\Downloads\vineyards.csv")
url = "https://ac-101708228-virtuoso-prod.s3.amazonaws.com/uploads/download/119/city_lat_long.csv"
urlretrieve(url,'city_lat_long.csv')
city_lat_long = pd.read_csv("city_lat_long.csv")

html_tables = pd.read_html(r"https://www.iban.com/country-codes")
alpha2_code = html_tables[0]
alpha2_code.drop(["Alpha-3 code","Numeric"],inplace=True,axis=1)

alpha2_code["Country"] = alpha2_code["Country"].replace("United States of America (the)","United States")
vineyards_alpha2 = vineyards.merge(alpha2_code, on="Country", how="left")
vineyards_city_lat_long = vineyards_alpha2.merge(city_lat_long, on=["Alpha-2 code","City"], how="left")
vineyards_city_lat_long.drop("Alpha-2 code", inplace=True, axis=1)

core_api = r"http://api.weatherapi.com/v1/forecast.json?"
api_key = ""

for i in range(len(vineyards_city_lat_long)):
    q = vineyards_city_lat_long.loc[i,"lat,long"]
    days = "3"
    url = core_api + "key=" + api_key + " &q=" + q + "&days=" + days + "&aqi=no&alerts=no"
    api_request = get(url)
    request_data = api_request.json()
    tmr = request_data["forecast"]["forecastday"][0]["day"]["mintemp_c"] 
    vineyards_city_lat_long.loc[i,"Today+1 Min Temp"] = tmr
    tmr1 = request_data["forecast"]["forecastday"][1]["day"]["mintemp_c"] 
    vineyards_city_lat_long.loc[i,"Today+2 Min Temp"] = tmr1
    tmr2 = request_data["forecast"]["forecastday"][2]["day"]["mintemp_c"]
    vineyards_city_lat_long.loc[i,"Today+3 Min Temp"] = tmr2

vineyards_city_lat_long

#Reset Options
pd.reset_option('display.max_rows')
pd.reset_option('display.max_columns')    

