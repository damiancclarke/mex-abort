# municipPrep.py v0.00           damiancclarke             yyyy-mm-dd:2014-10-10
#---|----1----|----2----|----3----|----4----|----5----|----6----|----7----|----8
#
#
# This file converts various files in a range of xls formats to csv output to i-
# ncorporate into a data file.  It uses the following data:
#
#  > Employment data from ENOE
#  http://www3.inegi.org.mx/sistemas/tabuladosbasicos/tabdirecto.aspx?s=est&c=29188
#   - This has one sheet per Entidad Federativa with unemployment by trimester
#  > Municipal Socioeconomic data from SEGOB
#  http://www.inafed.gob.mx/es/inafed/Municipales
#   - This has a range of sheets:
#       siha_2_2_1.xls: Ingresos Brutos Municipales (1989-2010)
#       siha_2_2_2.xls: Egresos Brutos Municipales (1998-2010)
#       siha_2_2_5_2.xls: Infraestructura Educativa por Municipio (2005-2010)
#       siha_2_2_5_5.xls: Personal Medico por Municipio (2005-2010)
#       siha_2_2_5_5.xls: Personal Medico por Municipio (2005-2010)
#       siha_2_2_5_7.xls: Personal en Educacion por Municipio (2005-2010)
#       siha_2_2_5_8.xls: Alumnos en Educacion por Municipio (2005-2010)
#       siha_2_2_5_10.xls: Escuelas por Municipio (2005-2010)
#
#  All data locations and files are listed in section 1
#
#
#  contact: mailto:damian.clarke@economics.ox.ac.uk
#

import os
import xlrd
import csv

#-------------------------------------------------------------------------------
#--- (1) Locations on system
#-------------------------------------------------------------------------------
labour = '~/investigacion/2014/MexAbort/Data/Labour/Desocupacion2000_2014/'
municp = '~/investigacion/2014/MexAbort/Data/Municip/'

states = ['aguascalientes','baja_california_sur','baja_california','campeche',
          'chiapas','chihuahua','coahuila_de_zaragoza','colima','distrito_federal',
          'durango','guanajuato','guerrero','hidalgo','jalisco','mexico',
          'michoacan_de_ocampo','morelos','nayarit','nuevo_leon','oaxaca','puebla',
          'queretaro','quintana_roo','san_luis_potosi','sinaloa','sonora',
          'tabasco','tamaulipas','tlaxcala','veracruz_de_ignacio_de_la_llave', 
          'yucatan','zacatecas']

for s in states:
    print s
