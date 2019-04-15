#!/usr/bin/env python3

import os

path = "."

result_file="names,latencies\n"

files = os.listdir(path)
files.sort()
for name in files:
    if not name.endswith(".out"):
        continue
    name_replaced = name.replace("_", "-")
    name_splitted = name_replaced.split("-")
    if name_splitted[1] == "latency":
        print(name)
        latency_file = open(name, "r")
        for line in latency_file:
            if line.startswith("LAT - "):
                result_file += line.replace("LAT - ", name_splitted[0] + "-" + name_splitted[2] + ",")
csv_file = "kafka-latencies-boxplot.csv"
with open(csv_file, "w") as csvfile:
    csvfile.write(result_file)
