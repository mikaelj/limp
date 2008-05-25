#!/usr/bin/env python

from BeautifulSoup import BeautifulSoup
import re
import os
import glob
import sys

g_symbol2data = {}
g_symbol2sections = {}
g_section_tags = [ "Syntax:"
                  ,"Description:"
                  ,"Method Signatures:"
                  ,"Examples:"
                  ,"Affected By:"
                  ,"Exceptional Situations:"
                  ,"See Also:"
                  ,"Side Effects:"
                  ,"Notes."
                  ]


def read_file(path):
    lines = open(path).readlines()
    return BeautifulSoup(''.join(lines))

def vim_as_tag(s):
    # XXX: Fixme. Doesn't work.
    #for symbol in g_symbol2sections.keys():
    #        s = s.replace(symbol, '|'+symbol+'|')
    return s

def xml_markup_fixup(s):
    return s.replace("&amp;", "&").replace('&quot;', '"').replace("&lt;", "<").replace("&gt;", ">").replace(" .", ".").replace(" ;", ";").replace(" ,", ",")

def vim_description(s, convert_symbol_to_tags=False):
    "Split into 70-column lines, right-justified w/ 8 spaces."

    # vim markup fixup
    if convert_symbol_to_tags:
        s = vim_as_tag(s)
    
    # change earmuffs into \earmuff
    s = s.replace('*', '\\*')

    lines = []
    for para in s.split('\n'):
        line = []
        for w in para.split():
            length = len(' '.join(line))
            if length + len(w) < 79:
                line.append(w)
            else:
                lines.append(' '.join(line))
                line = [w]

        lines.append(' '.join(line))

    s = ' '*8 + ('\n'+' '*8).join(lines)
    return s

def extract_section(soup, symbol):
    """Return (next soup, current section contents, current section name)"""
    section = []

    # assume this is only happens at the end of the file
    if soup.contents[0] == u'\n':
        return None, [], ""

    if len(soup.contents) == 2:
        if soup.contents[1].strip() == u'None.':
            # the section is noted as empty, forward to next section
            return soup.nextSibling.nextSibling, [], ""

    # it's most likely it's here, but not sure. oh well!
    title = soup.contents[0].string
    #print >> sys.stderr, "SYMBOL:", symbol, "[", title, "]"

    soup = soup.nextSibling.nextSibling

    lines = []
    while soup and len(soup.findAll(text=re.compile("[A-Z][a-z]+:"))) == 0:
        # fix for Examples
        line = [e.strip() for e in soup.recursiveChildGenerator()
                if isinstance(e, unicode)]
        lines.append(' '.join(line))
        soup = soup.nextSibling

    if len(lines):
        soup_data = '\n'.join(lines)

        # xml-ish markup fixup
        section = xml_markup_fixup(soup_data)

    return soup, section, title

def extract_symbol_info(symbol, soup):
    "Expects a lower-case unicode symbol name"

    #
    # read through the the sections
    #
    g_symbol2sections[symbol] = {}

    # special-case Syntax (first item) to start from a known location
    soup = soup.find(text=u'Syntax:').parent.parent
    soup, section, title = extract_section(soup, symbol)
    if title and section:
        g_symbol2sections[symbol][title] = section

    # rest of the sectionv
    while soup:
        soup, section, title = extract_section(soup, symbol)
        if title and section:
            g_symbol2sections[symbol][title] = section


#
# ==================================================================================
#

#-4:-3 bombs on f_upper_.htm (more than one syntax item)
#-8:-5 works
functions = glob.glob("/usr/share/doc/hyperspec/Body/f_*")
macros = glob.glob("/usr/share/doc/hyperspec/Body/m_*")
for path in functions + macros:
    print >> sys.stderr, "Reading", path
    soup = read_file(path)

    symbols = soup.findAll(lambda tag: tag.name == u"a" and tag.get('name', None) != None)
    for symbol in symbols:
        s = symbol.get('name')
        g_symbol2data[s] = (path, soup)

for symbol, (path, soup) in g_symbol2data.items():
    print >> sys.stderr, "  +", symbol
    extract_symbol_info(symbol, soup)

symbols = g_symbol2sections.keys()
symbols.sort()
for symbol in symbols:
    print " "*(79-len(symbol)-3), "*%s*" % symbol.lower()

    s = g_symbol2sections[symbol]
    if "Syntax:" in s:
        syntax = s["Syntax:"]

        lines = syntax.split('\n')
        for line in lines:
            line = line.strip().lower()
            if line.startswith(symbol.lower()+" "):
                parts = line.split()
                form = [parts[0]]
                i = 1
                for arg in parts[i:]:
                    arg.strip()
                    if arg == u"=>":
                        break
                    if arg.startswith(u'&'):
                        fmt = '%s'
                    else:
                        fmt = '{%s}'

                    form.append(fmt % arg)
                    i += 1

                print " ".join(form + parts[i:])

    if "Arguments and Values:" in s:
        print vim_description(s["Arguments and Values:"])
    if "Description:" in s:
        print " "*8 + "Description:\n", vim_description(s["Description:"], True)
    #if "Examples:" in s:
    #    print " "*8 + "Examples:\n", s["Examples:"] #vim_description(s["Examples:"])
    if "Exceptional Situations:" in s:
        print " "*8 + "Exceptional Situations:\n", vim_description(s["Exceptional Situations:"], True)
    if "See Also:" in s:
        print " "*8 + "See Also:\n", vim_description(s["See Also:"], True)


