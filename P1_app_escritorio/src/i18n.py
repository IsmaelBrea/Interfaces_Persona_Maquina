import gettext
import locale
import os
from datetime import datetime

def setup_locale():
    # Try to use the system's locale
    try:
        locale.setlocale(locale.LC_ALL, '')
    except locale.Error:
        # If system locale is not available, fall back to 'es_ES.UTF-8'
        locale.setlocale(locale.LC_ALL, 'es_ES.UTF-8')
    
    # Get the current locale
    current_locale, encoding = locale.getlocale()
    language = current_locale.split('_')[0] if current_locale else 'es'

    # Set up the translations
    localedir = os.path.join(os.path.abspath(os.path.dirname(__file__)), 'locale')
    translate = gettext.translation('patient_management', localedir, languages=[language], fallback=True)
    global _
    _ = translate.gettext

def format_date(date_string):
    # Parse the date string and format it according to the current locale
    date = datetime.strptime(date_string, '%Y-%m-%d')
    return locale.format_string('%x', date.timetuple())

def format_number(number):
    # Format the number according to the current locale
    return locale.format_string('%.2f', number, grouping=True)

# Call setup_locale() when this module is imported
setup_locale()