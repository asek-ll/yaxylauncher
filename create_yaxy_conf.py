import os
import xml.etree.ElementTree as ET

base_path = os.path.join("w:/", "transas-plugins")
atlassian_plugin_part = os.path.join('src', 'main', 'resources', 'atlassian-plugin.xml')

target_host = "j6\.transas\.com"
plugins = [
        {'dir': 'utils', 'name': 'utils'},
        {'dir': 'pm', 'name': 'pm'},
        {'dir': 'gantt', 'name': 'gantt'},
        {'dir': 'testers', 'name': 'testers'},
        {'dir': 'activities', 'name': 'activities'},
        {'dir': 'jet', 'name': 'jet'},
        {'dir': 'pm-issue-decorator', 'name': 'pm.issue.decorator'},
        {'dir': 'jira-home-link', 'name': 'jira-home-link'},
        {'dir': 'bt', 'name': 'bt'},
        {'dir': 'hr', 'name': 'hr'},
        {'dir': 'swdb', 'name': 'swdb'},
        {'dir': 'wishlist', 'name': 'wishlist'},
        {'dir': 'tr', 'name': 'tr'},
        {'dir': 'jiratech-metrics', 'name': 'jiratech-metrics'},
        ]

ext_black_list = [
        '.soy',
        '.less'
        ]

conf = open("plugin_resources.txt", "w")
conf.write("# vim: ft=config\n")
conf.write("[generated]\n")
for plugin in plugins:
    plugin_dir = plugin['dir']
    plugin_name = plugin['name']
    plugin_key = 'transas.jira6.'+plugin_name
    conf.write("[" + plugin_name + "]\n")

    plugin_path = os.path.join(base_path, plugin_dir)

    atlassian_plugin_xml = os.path.join(plugin_path, atlassian_plugin_part)

    with open (atlassian_plugin_xml, "r") as file:
        xml=file.read().replace('\n', '')

    root = ET.fromstring(xml)

    for child in root:
        if child.tag == 'web-resource':
            key = child.attrib['key']
            for resource in child:
                if resource.tag == 'resource':
                    name = resource.attrib['name']
                    location = resource.attrib['location']

                    is_static = False
                    for param in resource:
                        if param.attrib['name'] == 'source':
                            is_static = param.attrib['value'] == 'webContextStatic'

                    if is_static:
                        continue

                    basename, ext = os.path.splitext(location)
                    if ext in ext_black_list:
                        continue

                    resource_path = 'download/resources/' + plugin_key + ":" + key + "/" + name
                    file_path = os.path.join(plugin_path, "src", "main", "resources", location).replace("\\", "/")

                    if resource_path[-1:] == "/":
                        resource_path += "(.+)$"
                        file_path += "$1"
                    else:
                        resource_path += "$"

                    if target_host:
                        resource_path = target_host + ".+" + resource_path

                    yaxy_rule = "/" + resource_path + "/ => file://" + file_path
                    conf.write(yaxy_rule + "\n")

    conf.write("\n")


