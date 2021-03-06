# -*- coding: utf-8 -*-

"""
***************************************************************************
    FixedDistanceBuffer.py
    ---------------------
    Date                 : August 2012
    Copyright            : (C) 2012 by Victor Olaya
    Email                : volayaf at gmail dot com
***************************************************************************
*                                                                         *
*   This program is free software; you can redistribute it and/or modify  *
*   it under the terms of the GNU General Public License as published by  *
*   the Free Software Foundation; either version 2 of the License, or     *
*   (at your option) any later version.                                   *
*                                                                         *
***************************************************************************
"""

__author__ = 'Victor Olaya'
__date__ = 'August 2012'
__copyright__ = '(C) 2012, Victor Olaya'
# This will get replaced with a git SHA1 when you do a git archive
__revision__ = '$Format:%H$'

import os.path

from PyQt4 import QtGui
from PyQt4.QtCore import *

from qgis.core import *

from sextante.core.GeoAlgorithm import GeoAlgorithm
from sextante.core.QGisLayers import QGisLayers

from sextante.parameters.ParameterVector import ParameterVector
from sextante.parameters.ParameterBoolean import ParameterBoolean
from sextante.parameters.ParameterNumber import ParameterNumber

from sextante.outputs.OutputVector import OutputVector

from sextante.algs.ftools import Buffer as buff

class FixedDistanceBuffer(GeoAlgorithm):

    INPUT = "INPUT"
    OUTPUT = "OUTPUT"
    FIELD = "FIELD"
    USE_SELECTED = "USE_SELECTED"
    DISTANCE = "DISTANCE"
    SEGMENTS = "SEGMENTS"
    DISSOLVE = "DISSOLVE"

    #===========================================================================
    # def getIcon(self):
    #    return QtGui.QIcon(os.path.dirname(__file__) + "/icons/buffer.png")
    #===========================================================================

    def defineCharacteristics(self):
        self.name = "Fixed distance buffer"
        self.group = "Vector geometry tools"

        self.addParameter(ParameterVector(self.INPUT, "Input layer", ParameterVector.VECTOR_TYPE_ANY))
        self.addParameter(ParameterBoolean(self.USE_SELECTED, "Use selected features", False))
        self.addParameter(ParameterNumber(self.DISTANCE, "Distance", 0.0, default=10.0))
        self.addParameter(ParameterNumber(self.SEGMENTS, "Segments", 1, default=5))
        self.addParameter(ParameterBoolean(self.DISSOLVE, "Dissolve result", False))

        self.addOutput(OutputVector(self.OUTPUT, "Buffer"))

    def processAlgorithm(self, progress):
        layer = QGisLayers.getObjectFromUri(self.getParameterValue(self.INPUT))
        useSelection = self.getParameterValue(self.USE_SELECTED)
        distance = self.getParameterValue(self.DISTANCE)
        dissolve = self.getParameterValue(self.DISSOLVE)
        segments = int(self.getParameterValue(self.SEGMENTS))

        provider = layer.dataProvider()
        writer = self.getOutputFromName(self.OUTPUT).getVectorWriter(layer.pendingFields(),
                     QGis.WKBPolygon, provider.crs())

        buff.buffering(progress, writer, distance, None, useSelection, False,
                       layer, dissolve, segments)
