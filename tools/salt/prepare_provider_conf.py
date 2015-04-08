from jinja2 import Environment, FileSystemLoader
import os

config_dir = "salt/cloud.providers.d"
env = Environment(loader=FileSystemLoader(config_dir))

for f in os.listdir(config_dir):
    if os.path.isfile(os.path.join(config_dir, f)):
        f_name, f_ext = os.path.splitext(f)
        if f_ext == ".template":
            target_name = f_name.replace("_", ".")
            template = env.get_template(f)
            with open(config_dir + "/" + target_name, "w") as f:
                f.write(template.render(env=os.environ))
