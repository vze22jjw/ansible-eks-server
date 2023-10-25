#!.virt_env/bin/python

import argparse
import json
import os
import sys

class Formatter(argparse.RawTextHelpFormatter):
    # use defined argument order to display usage
    def _format_usage(self, usage, actions, groups, prefix):
        if prefix is None:
            prefix = 'usage: '

        # if usage is specified, use that
        if usage is not None:
            usage = usage % dict(prog=self._prog)

        # if no optionals or positionals are available, usage is just prog
        elif usage is None and not actions:
            usage = '%(prog)s' % dict(prog=self._prog)
        elif usage is None:
            prog = '%(prog)s' % dict(prog=self._prog)
            # build full usage string
            action_usage = self._format_actions_usage(actions, groups) # NEW
            usage = ' '.join([s for s in [prog, action_usage] if s])
            # omit the long line wrapping code
        # prefix with 'usage:'
        return '%s%s\n\n' % (prefix, usage)


def get_allowed_ops():
    return [op.replace(' ', '').replace('\n', '') for op in os.environ.get('ALLOWED_OPERATIONS', '').split(',')]


def get_operation_parser(force_help):
    allowed_ops = get_allowed_ops()

    parser = argparse.ArgumentParser(
        add_help=force_help,
        prog=os.environ.get('PROG') or sys.argv[0],
        formatter_class=Formatter,
        epilog="Where operation is one of:\n    %s" % (', '.join(allowed_ops))
    )
    parser.add_argument(
        dest='operation',
        metavar='operation',
        choices=allowed_ops,
        help="operation to perform"
    )
    return parser


def get_parser(stack_type, do_configs, mode=None, operation=None, ansible=False):
    parser = argparse.ArgumentParser(
        add_help=True,
        prog=os.environ.get('PROG') or sys.argv[0],
        formatter_class=Formatter,
        epilog=ansible and "Note: any additional arguments provided are passed to the ansible playbook." or ""
    )
    parser.add_argument(
        dest='operation',
        metavar=operation or 'operation',
        choices=operation and [operation] or get_allowed_ops(),
        help="operation to perform"
    )
    if do_configs:
        parser.add_argument(
            '-%s' % stack_type[0],
            '--%s' % stack_type,
            dest='stack',
            metavar=stack_type,
            required=True,
            help="name of the %s" % stack_type
        )
    return parser


if __name__ == "__main__":
    stack_type = sys.argv[1]
    do_configs = sys.argv[2] and sys.argv[2].lower() == 'true'
    mode = sys.argv[3].lower()
    params = sys.argv[4:]

    operation_only_mode = mode and mode.lower() == 'operation_only'

    if operation_only_mode:
        # If no params (other than the help param) force the help parameter
        force_help = len([a for a in params if a not in ['-h', '--help']]) == 0
        parser = get_operation_parser(
            force_help = force_help
        )
    else:
        operation = os.environ.get('OPERATION') or None
        parser = get_parser(
            stack_type,
            do_configs,
            mode = mode,
            operation = operation,
            ansible = True
        )
        more_args = json.loads(os.environ.get('MOREARGS') or '{"args": []}')['args']
        for new in more_args:
            parser.add_argument(
                *new['flags'],
                **new['params']
            )
        
        help_args = json.loads(os.environ.get('HELPARGS') or '{"helpargs": []}', strict=False)['helpargs']
        for new in help_args:
            parser.add_argument_group(
                new['name'],
                new['description']
            )

    args, unknown = parser.parse_known_args(params)

    print('PARSE_SUCCESS=YES')
    print(('OPERATION="%s"' % args.operation))

    if not operation_only_mode:
        if do_configs:
            print(('STACK="%s"' % args.stack))
        for new in more_args:
            print(('%s="%s"' % (new['params']['dest'].upper(), getattr(args, new['params']['dest']) or "")))
        print(('UNPARSED="%s"' % ' '.join(u.replace('"', '\\"') for u in unknown)))


