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
		print(machine["name"])
		if machine.get("variables") is None:
			print("MISSING VARIABLES KEY")
			return 1
		for _, value in machine["variables"].items():
			defined_variables += value

		if machine["variables"].get("api") is not None:
			missing_endpoints = []
			for api in 	machine["variables"]["api"]:
				if data.get("api_endpoints") is None or data["api_endpoints"].get(api) is None:
					missing_endpoints.append(api)
			if missing_endpoints:
				print("MISSING ENDPOINTS FOR API VARIABLES: ", missing_endpoints)
				return 1

		tf = Terraform(working_dir=machine["terraform_folder"])
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
					print("THERE ARE MISSING VARIABLES, WHICH ARE DEFINED IN %s, PLEASE SPECIFY THEM IN config.json" %machine["name"])
					print("MISSING VARIABLES: ", missing_variables)
					return 1
			else:
				print("UNKNOWN ERROR")
				return 1

assert check_config() == 0
	

#t.apply(input = True, var = {"floating_ip": "78.128.250.94", "token":"gAAAAABgXc2yr5VbgeJqpErCFejH7idVZe6St7EsWJrVS6136E6TSmljtq42f3rkmV-YSX8SeEnC-KqoNdPZLYnRZiDu44r_F69l_ajg1VRaoEabYJitalumE0HKMlowY5D55WvL7XDftD29AG4oj10eaaQ0XTSMQH6ZLubT2Gs2W9qz-n2Ih_fQnWkEcJnctqPAjdJKmtHC", "ssh": "key", "local_network_id": "03b21c24-910f-4ec5-a8f3-419db219b383"}, skip_plan = True)
