from python_terraform import Terraform
from os import listdir
import json
import re
def get_variables_from_log(log):
	p = re.compile(r': variable "[[a-z]+[\_[a-z]*')
	res = p.findall(log)
	for i in range(len(res)):
		res[i] = res[i].replace(': variable "', '')
	return res

def check_config():
	defined_variables = []

	with open('configurations.json') as json_file:
		data = json.load(json_file)
	for machine in data["machines"]:
		if machine["name"] == "terraform":
                        continue
		print("\n", machine["name"],)
		if machine.get("variables") is None:
			print("MISSING VARIABLES KEY")
			return 1
		for _, value in machine["variables"].items():
			defined_variables += value

		if machine["variables"].get("api") is not None:
			missing_endpoints = []
			for api in 	machine["variables"]["api"]:
				if data.get("api_endpoints") is None or \
						data["api_endpoints"].get(api) is None:
					missing_endpoints.append(api)
			if missing_endpoints:
				print("MISSING ENDPOINTS FOR API VARIABLES: ", missing_endpoints)
				return 1

		tf = Terraform(working_dir=machine["name"])
		code, err, log = tf.plan()
		if code:
			if log.find("No configuration files") != -1:
				print("NO TERRAFORM FILE FOUND, PLEASE CREATE ONE")
				return 1
			if log.find("No value for required variable"):
				variables = get_variables_from_log(log)
				missing_variables = []
				for var in variables:
					if var not in defined_variables:
						missing_variables.append(var)
				if missing_variables:
					print("THERE ARE MISSING VARIABLES, WHICH ARE DEFINED IN %s, "
						  "PLEASE SPECIFY THEM IN config.json" %machine["name"])
					print("MISSING VARIABLES: ", missing_variables)
					return 1
			else:
				print("UNKNOWN ERROR")
				return 1
	return 0


assert check_config() == 0
