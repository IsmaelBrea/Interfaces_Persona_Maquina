#!/usr/bin/env python

from model import PatientModel
from view import View
from presenter import PatientPresenter


if __name__ == "__main__":
   
    presenter = PatientPresenter(model=PatientModel(), view=View())
    presenter.run(application_id="gal.udc.fic.ipm.PatientList")