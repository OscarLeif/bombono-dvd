import SCons
import re
import os

def GetDefEnv():
    import SCons.Defaults
    return SCons.Defaults.DefaultEnvironment(tools=['mingw'] if os.name == 'nt' else ['default'])

def IsSConsLE_0_96(env):
    """ Is SCons version <= 0.96 """
    if '_get_major_minor' in dir(env) and '__version__' in dir(SCons):
        v_major, v_minor = env._get_major_minor(SCons.__version__)
        if (v_major, v_minor) <= (0, 96):
            return 1
    return 0

def IsSConsVersionGE(triple):
    # Modern SCons no longer exposes the private environment version parser.
    version = tuple(int(n) for n in re.findall(r'\d+', SCons.__version__)[:3])
    return version + (0,) * (3 - len(version)) >= tuple(triple)

def MakeGenAction(function, strfunction=None):
    if IsSConsVersionGE((1, 2, 0)):
        # official way to create Action generator
        kw = {}
        if strfunction:
            kw['strfunction'] = strfunction
        act = SCons.Action.Action(function, generator=1, **kw)
    else:
        act = SCons.Action.CommandGeneratorAction(function)
    return act


