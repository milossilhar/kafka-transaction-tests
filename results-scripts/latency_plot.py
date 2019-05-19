#!/usr/bin/env python3

import os

path = "."

resultDict={}

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
            if line.startswith("AVG - "):
                category = name_splitted[0] + "_" + name_splitted[2]
                if not category in resultDict:
                    resultDict[category]=[]
                newLine = line.replace("\n", "")
                resultDict[category].append(newLine.replace("AVG - ", ""))

CSV_FILE = "latency_plot.csv"

header = ",".join(resultDict.keys()) + "\n"
maxRuns = max(list(map(len, resultDict.values())))
for key, listValue in resultDict.items():
    if len(listValue) < maxRuns:
        diff = maxRuns - len(listValue)
        resultDict[key] = listValue + [0 * i for i in range(diff)]

resultFile = ""
for i in range(maxRuns):
    resultFile += ",".join(list(map(lambda x: str(x[i]), resultDict.values()))) + "\n"

with open(CSV_FILE, "w") as csvfile:
    csvfile.write(header)
    csvfile.write(resultFile)
