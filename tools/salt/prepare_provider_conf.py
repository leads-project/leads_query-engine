from jinja2 import Environment, FileSystemLoader
import os

config_file_name = "cah_hamm5"
src_template = "{}_conf.template".format(config_file_name)
target_name = "{}.config".format(config_file_name)
config_dir = "salt/cloud.providers.d"

env = Environment(loader=FileSystemLoader(config_dir))
template = env.get_template(src_template)

with open(config_dir + "/" + target_name, "w") as f:
    f.write(template.render(env=os.environ))
