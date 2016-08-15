# This is a useful filter for finding an item in a list, e.g. this will only run
# a task when the 'site' database is newly created:
#    when: created_dbs.results | byattr('db', 'site') | first | changed
# Source:
# https://github.com/ansible/ansible/issues/8836#issuecomment-67747806
def byattr_filter(list, key, value):
    return filter(lambda t: t[key] == value, list)

class FilterModule(object):
    def filters(self):
        return {
            'byattr': byattr_filter
        }
