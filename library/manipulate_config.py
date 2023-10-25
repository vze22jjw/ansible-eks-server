#!.virt_env/bin/python

import sys
import yaml
from optparse import OptionParser


def manipulate_config(stack_type, args):
    USAGE = """
    %%prog --%s=%s --config=CONFIG KEY:VALUE KEY:VALUE ...
    """ % (stack_type, stack_type.upper())

    try:
        parser = OptionParser(USAGE)
        parser.add_option('--config', dest='config', help="")
        parser.add_option('--values', dest='values', help="")

        (options, args) = parser.parse_args(args)
        if not options.config:
            parser.error("You must specify a config")

        stream = open(options.config, 'r').read()
        config = yaml.safe_load(stream)

        for arg in args:
            key, value = arg.split(":")
            config['%s_config' % stack_type][key] = value

        with open(options.config, "w") as config_file:
            config_file.write(yaml.dump(config))

    except KeyboardInterrupt:
        print()


if __name__ == '__main__':
    manipulate_config(sys.argv[1], sys.argv[2:])
