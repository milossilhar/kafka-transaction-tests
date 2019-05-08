#!/usr/bin/env python3

import os

path = "."

def size_to_index(size):
    if (size == "50kB"):
        return 0
    if (size == "100kB"):
        return 1
    if (size == "200kB"):
        return 2
    if (size == "500kB"):
        return 3
    if (size == "1MB"):
        return 4
    if (size == "5MB"):
        return 5

resultDict={}

files = os.listdir(path)
files.sort()
for name in files:
    if not name.endswith(".out"):
        continue
    name_replaced = name.replace("_", "-")
    name_splitted = name_replaced.split("-")
    if name_splitted[0] == "3server" and name_splitted[1] == "size":
        print(name)
        size_file = open(name, "r")
        for line in size_file:
            if line.startswith("MPS - "):
                category = "con-" + name_splitted[0] + "-" + name_splitted[2]
                if not category in resultDict:
                    resultDict[category]=[None]*6
                newLine = line.replace("\n", "")
                resultDict[category][size_to_index(name_splitted[3])] = newLine.replace("MPS - ", "")

CSV_FILE = "size_plot_acks_msg.csv"

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

