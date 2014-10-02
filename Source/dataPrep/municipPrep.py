# municipPrep.py v0.00           damiancclarke             yyyy-mm-dd:2014-10-10
#---|----1----|----2----|----3----|----4----|----5----|----6----|----7----|----8
#
#
# This file converts various files in a range of xls formats to csv output to i-
# ncorporate into a data file. Non unicode characters make this a bit of a head-
# ache.  I use a regex to strip unicodes from imported xls files.  Ths script u-
# ses the following data:
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
import sys
import xlrd
import csv
import re
import codecs

#-------------------------------------------------------------------------------
#--- (1) Locations on system
#-------------------------------------------------------------------------------
base   = '/home/damiancclarke/investigacion/2014/MexAbort/'
labour = base + 'Data/Labour/Desocupacion2000_2014/'
municp = base + 'Data/Municip/'

states = ['aguascalientes','baja_california','baja_california_sur','campeche',
          'coahuila_de_zaragoza','colima','chiapas','chihuahua','distrito_federal',
          'durango','guanajuato','guerrero','hidalgo','jalisco','mexico',
          'michoacan_de_ocampo','morelos','nayarit','nuevo_leon','oaxaca','puebla',
          'queretaro','quintana_roo','san_luis_potosi','sinaloa','sonora',
          'tabasco','tamaulipas','tlaxcala','veracruz_de_ignacio_de_la_llave', 
          'yucatan','zacatecas']
number = ['01','02','03','04','05','06','07','08','09','10','11','12','13','14',
          '15','16','17','18','19','20','21','22','23','24','25','26','27','28',
          '29','30','31','32']

#-------------------------------------------------------------------------------
#--- (2) Dump labour data for each state into csv
#-------------------------------------------------------------------------------
fstr = '_tasa_de_desocupacion_total_trimestral.xls'
expr = '\'/"2000",,,,,,,,/{flag=1;next}/Nota/{flag=0}flag\' '

for n,s in enumerate(states):
    print 'Converting' + number[n], s + 'to csv'
    os.system('xls2csv '+labour+s+fstr + '>' + labour+s+'.csv')
    os.system('awk ' + expr + labour + s +'.csv >' + labour + s +'out.csv')
    os.remove(labour+s+'.csv')
    ifile = open(labour+s+'out.csv', 'r')
    ofile = open(labour+s+'.csv', 'w')
    year = 2000
    ofile.write('\"State\",\"Number\",\"year\",\"trimeter\",\"Desocup\",\"dDes\",'+
                '\"Deseason\",\"dSea\",\"trend\",\"dTre\"'+'\n')
    for i,line in enumerate(ifile):
        if i<4:
            ofile.write('\"' + s + '\",'+'\"' + number[n] + '\",'+'\"' + str(year) 
                        + '\",'+line)
        else:
            if (i-4)%5 == 0:
                year = year + 1
                print year
            else:
                ofile.write('\"' + s + '\",'+'\"' + number[n] + '\",'+'\"' + 
                            str(year) + '\",'+line)

    ifile.close()
    ofile.close()
    os.remove(labour+s+'out.csv')

#-------------------------------------------------------------------------------
#--- (3) Dump other municipalty files
#-------------------------------------------------------------------------------
