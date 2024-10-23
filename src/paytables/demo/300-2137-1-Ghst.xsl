<?xml version="1.0" encoding="UTF-8"?><xsl:stylesheet version="1.0" exclude-result-prefixes="java" extension-element-prefixes="my-ext" xmlns:lxslt="http://xml.apache.org/xslt" xmlns:java="http://xml.apache.org/xslt/java" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:my-ext="ext1">
<xsl:import href="HTML-CCFR.xsl"/>
<xsl:output indent="no" method="xml" omit-xml-declaration="yes"/>
<xsl:template match="/">
<xsl:apply-templates select="*"/>
<xsl:apply-templates select="/output/root[position()=last()]" mode="last"/>
<br/>
</xsl:template>
<lxslt:component prefix="my-ext" functions="formatJson retrievePrizeTable">
<lxslt:script lang="javascript">
					
function formatJson(jsonContext, translations, prizeValues, prizeNamesDesc) {
	var scenario = getScenario(jsonContext);
	var tranMap = parseTranslations(translations);
	var prizeMap = parsePrizes(prizeNamesDesc, prizeValues);
	return doFormatJson(scenario, tranMap, prizeMap);

}
function ScenarioConvertor(scenario, currency) {
	this.scenario = scenario;
	this.baseScenarioSplit = this.scenario.split("|")[0].split(",");
	this.extraTurns = this.getExtraTurns();
	//this.extraTurns = this.baseScenarioSplit.length - 5;
	this.currency = currency;
}
ScenarioConvertor.prototype.getExtraTurns = function () {
	var totalTurns = 0;
	var baseScenarioSplit = this.baseScenarioSplit;
	for (var i = 0; i &lt; baseScenarioSplit.length; i++) {
		if (/\w/.test(baseScenarioSplit[i])) {
			totalTurns++;
		}
	}
	return totalTurns - 5 &gt; 0 ? totalTurns - 5 : "No";
};
ScenarioConvertor.prototype.generateOutCome = function () {
	var len = this.baseScenarioSplit.length;
	var outComeTable = [];
	for (var i = 0; i &lt; len - 1; i++) {
		var row = [];
		var subStrFrom =  - (1 + i); // -1,-2,-3
		for (var j = 0; j &lt; len; j++) {
			var str = this.baseScenarioSplit[j].substr(subStrFrom, 1);
			if (str !== '.') {
				row.push(this.baseScenarioSplit[j].substr(subStrFrom, 1));
			} else {
				row.push('');
			}
		}
		outComeTable.push(row);
	}
	return outComeTable;
}

ScenarioConvertor.prototype.getTotalMovesAndPaytable = function (stepsMap, prizeMap, prizeBoat) {
	var outComeTable = this.generateOutCome();
	var movesAndPaytable = [];
	var currency = this.currency;
	for (var i = 0; i &lt; outComeTable.length; i++) {
		var steps = 0,
		multiply = 1,
		winPrize = 0;
		var winPrize;
		for (var j = 0; j &lt; outComeTable[i].length; j++) {
			if (isNaN(outComeTable[i][j])) {
				if (outComeTable[i][j] === 'X') {
					multiply *= 2;
				}
			} else {
				steps += Number(outComeTable[i][j]);
			}
		}
		movesAndPaytable.push({
			"steps": steps,
			"multiply": multiply
		});
	}

	var pickBonusScenario = this.scenario.split("|")[1].split(':');
	var winIndex = pickBonusScenario[0];
	if (winIndex === '0') {}
	else {
		var boatMap = {
			'A': '6',
			'B': '5',
			'C': '4',
			'D': '3',
			'E': '2',
			'F': '1'
		};
		var winData = pickBonusScenario[1].split(',')[winIndex - 1];
		var charAt_0 = winData.charAt(0);
		if (charAt_0 === 'A' || charAt_0 === 'B' || charAt_0 === 'C' || charAt_0 === 'D' || charAt_0 === 'E' || charAt_0 === 'F') {
			var charAt_1 = winData.charAt(1);
			var index = boatMap[charAt_0] - 1;
			if (isNaN(charAt_1)) {
				movesAndPaytable[index].multiply *= 2;
			} else {
				movesAndPaytable[index].steps += Number(charAt_1);
			}
		}
	}

	var shellBonusScenario = this.scenario.split("|")[2].split(':');
	var winIndex = shellBonusScenario[0];
	if (winIndex === '0') {}
	else {
		var boatMap = {
			'A': '6',
			'B': '5',
			'C': '4',
			'D': '3',
			'E': '2',
			'F': '1'
		};
		var winData = shellBonusScenario[1].split(',')[winIndex - 1];
		var charAt_0 = winData.charAt(0);
		if (charAt_0 === 'A' || charAt_0 === 'B' || charAt_0 === 'C' || charAt_0 === 'D' || charAt_0 === 'E' || charAt_0 === 'F') {
			var charAt_1 = winData.charAt(1);
			var index = boatMap[charAt_0] - 1;
			if (isNaN(charAt_1)) {
				movesAndPaytable[index].multiply *= 2;
			} else {
				movesAndPaytable[index].steps += Number(charAt_1);
			}
		}
	}

	movesAndPaytable.forEach(function (item, index) {
		var winPrize = '--';
		if (item.steps &gt;= stepsMap[index]) {
			var payNumSplit = prizeMap[prizeBoat[index]].match(/\d+/g);
			var strNum = '';
			var payNum;
			payNumSplit.forEach(function (item, index) {
				if (index === payNumSplit.length - 1) {
					strNum += '.';
				}
				strNum += item;
			});
			payNum = Number.prototype.toFixed.call(strNum * (item.multiply), 2);
			(function(num){
				num = num.toString();
				var intPart=num.substring(0,num.indexOf('.'));
				var floatPart=num.substring(num.indexOf('.'));
				var str='';
				while(intPart.length&gt;3){
					var interIndex = intPart.length-3;
					str=','+intPart.substring(interIndex)+str;
					intPart=intPart.substring(0,interIndex);
				}
				str = intPart+str;
				payNum = str+floatPart;
			})(payNum);
			winPrize = currency + payNum;
		}
		item['winPrize'] = winPrize;
	});

	return movesAndPaytable;
}
ScenarioConvertor.prototype.getGemInstantWin = function () {
	var baseGameScenario = this.scenario.split("|")[0];
	var repeatNum = 0;
	for (var i = 0; i &lt; baseGameScenario.length; i++) {
		if (baseGameScenario.substr(i, 1) === "G") {
			repeatNum++;
		}
	}
	return repeatNum;
}

ScenarioConvertor.prototype.getBonusResult = function (boatMap, type, tranMap, prizeMap) {
	var bonusScenario;
	if (type === 1) {
		bonusScenario = this.scenario.split("|")[1].split(':');
	} else {
		bonusScenario = this.scenario.split("|")[2].split(':');
	}
	var winIndex = bonusScenario[0];
	if (winIndex === '0') {
		return 'No';
	} else {
		var winData = bonusScenario[1].split(',')[winIndex - 1];
		var charAt_0 = winData.charAt(0);
		switch (charAt_0) {
		case 'I':
			winEinstant = winData.charAt(2) === "1" ? prizeMap.IW1 : prizeMap.IW2;
			return winEinstant;
		case '+':
			return tranMap.extra;
		case 'G':
			return tranMap.G;
		case 'O':
			return tranMap.W;
		case 'H':
			return tranMap.H;
		default: {
				var charAt_1 = winData.charAt(1);
				if (isNaN(charAt_1)) {
					return 'Row' + boatMap[charAt_0] + ': 2X';
				} else {
					return 'Row' + boatMap[charAt_0] + ': ' + charAt_1;
				}
			}
		}
	}
}

function doFormatJson(scenario, tranMap, prizeMap) {
	var indicator = scenario.split("|")[0];
	var playGrid = scenario.split("|")[1];
	var boatMap = {
		'A': '6',
		'B': '5',
		'C': '4',
		'D': '3',
		'E': '2',
		'F': '1'
	};
	var stepsMap = [10, 11, 12, 13, 14, 15];
	var prizeBoat = {
		'0': 'F',
		'1': 'E',
		'2': 'D',
		'3': 'C',
		'4': 'B',
		'5': 'A'
	};
	var currency = prizeMap.A.match(/\D+/)[0];
	var result = new ScenarioConvertor(scenario, currency);
	var gemWinValue = 'No';
	if (result.getGemInstantWin() &gt; 2) {
		gemWinValue = prizeMap['G' + result.getGemInstantWin()];
	}
	var r = [];
	r.push('&lt;table border="0" cellpadding="2" cellspacing="1" width="100%" class="gameDetailsTable" style="table-layout:fixed"&gt;');
	r.push('&lt;tr&gt;');
	r.push('&lt;td class="tablehead" width="100%" colspan="8"&gt;');
	r.push(tranMap.outcomeLabel);
	r.push('&lt;/td&gt;');
	r.push('&lt;/tr&gt;');

	r.push('&lt;tr&gt;');
	r.push('&lt;td class="tablebody" width="23%"&gt;');
	r.push('&lt;/td&gt;');
	for (var i = 1; i &lt; 8; i++) {
		r.push('&lt;td class="tablebody" width="11%"&gt;');
		r.push(tranMap.turn + " " + i);
		r.push('&lt;/td&gt;');
	}
	r.push('&lt;/tr&gt;');
	result.generateOutCome().forEach(function (row, index) {
		r.push('&lt;tr&gt;');
		r.push('&lt;td class="tablebody" width="23%"&gt;');
		switch (index) {
		case 0:
			r.push(tranMap.row + ' 1');
			break;
		case 1:
			r.push(tranMap.row + ' 2');
			break;
		case 2:
			r.push(tranMap.row + ' 3');
			break;
		case 3:
			r.push(tranMap.row + ' 4');
			break;
		case 4:
			r.push(tranMap.row + ' 5');
			break;
		case 5:
			r.push(tranMap.row + ' 6');
			break;
		default:
			break;
		}
		r.push('&lt;/td&gt;');
		row.forEach(function (col) {
			r.push('&lt;td class="tablebody" width="11%"&gt;');
			if (isNaN(col)) {
				switch (col) {
				case '+':
					col = tranMap.extra;
					break;
				case 'X':
					col = '2X';
					break;
				case 'G':
					col = tranMap.G;
					break;
				case 'H':
					col = tranMap.H;
					break;
				default:
					col = tranMap.W;
					break;
				}
			}
			r.push(col);
			r.push('&lt;/td&gt;');
		});
		r.push('&lt;/tr&gt;');
	});
	r.push('&lt;tr&gt;');
	r.push('&lt;td class="tablebody" width="23%"&gt;');
	r.push(tranMap.extraSpin);
	r.push('&lt;/td&gt;');
	r.push('&lt;td class="tablebody" width="23%" colspan="7"&gt;');
	r.push(result.extraTurns);
	r.push('&lt;/td&gt;');
	r.push('&lt;/tr&gt;');
	r.push('&lt;tr&gt;');
	r.push('&lt;td class="tablebody" width="23%"&gt;');
	r.push(tranMap.gemInstantWin);
	r.push('&lt;/td&gt;');
	r.push('&lt;td class="tablebody" width="23%" colspan="7"&gt;');
	r.push(gemWinValue);
	r.push('&lt;/td&gt;');
	r.push('&lt;/tr&gt;');
	r.push('&lt;/table&gt;');

	r.push('&lt;div width="100%" class="blankStyle"&gt;');
	r.push('&lt;div/&gt;');

	r.push('&lt;table border="0" cellpadding="2" cellspacing="1" width="100%" class="gameDetailsTable" style="table-layout:fixed"&gt;');
	r.push('&lt;tr&gt;');
	r.push('&lt;td class="tablehead" width="100%" colspan="8"&gt;');
	r.push(tranMap.shellBonusTitle);
	r.push('&lt;/td&gt;');
	r.push('&lt;/tr&gt;');

	r.push('&lt;tr&gt;');
	r.push('&lt;td class="tablebody" width="23%"&gt;');
	r.push(tranMap.bonusResult);
	r.push('&lt;/td&gt;');
	r.push('&lt;td class="tablebody" width="23%" colspan="7"&gt;');
	r.push(result.getBonusResult(boatMap, 1, tranMap, prizeMap));
	r.push('&lt;/td&gt;');
	r.push('&lt;/tr&gt;');

	r.push('&lt;/table&gt;');

	r.push('&lt;div width="100%" class="blankStyle"&gt;');
	r.push('&lt;div/&gt;');

	r.push('&lt;table border="0" cellpadding="2" cellspacing="1" width="100%" class="gameDetailsTable" style="table-layout:fixed"&gt;');
	r.push('&lt;tr&gt;');
	r.push('&lt;td class="tablehead" width="100%" colspan="8"&gt;');
	r.push(tranMap.wheelBonusTitle);
	r.push('&lt;/td&gt;');
	r.push('&lt;/tr&gt;');

	r.push('&lt;tr&gt;');
	r.push('&lt;td class="tablebody" width="23%"&gt;');
	r.push(tranMap.bonusResult);
	r.push('&lt;/td&gt;');
	r.push('&lt;td class="tablebody" width="23%" colspan="7"&gt;');
	r.push(result.getBonusResult(boatMap, 2, tranMap, prizeMap));
	r.push('&lt;/td&gt;');
	r.push('&lt;/tr&gt;');

	r.push('&lt;/table&gt;');

	r.push('&lt;div width="100%" class="blankStyle"&gt;');
	r.push('&lt;div/&gt;');
	r.push('&lt;table border="0" cellpadding="2" cellspacing="1" width="50%" class="gameDetailsTable" style="table-layout:fixed"&gt;');
	r.push('&lt;tr&gt;');
	r.push('&lt;td class="tablebody" width="23%"&gt;');
	r.push('&lt;/td&gt;');
	r.push('&lt;td class="tablebody" width="11%"&gt;');
	r.push(tranMap.totalMoves);
	r.push('&lt;/td&gt;');
	r.push('&lt;td class="tablebody" width="11%"&gt;');
	r.push(tranMap.targetMoves);
	r.push('&lt;/td&gt;');
	r.push('&lt;td class="tablebody" width="11%"&gt;');
	r.push(tranMap.winPrizeLabel);
	r.push('&lt;/td&gt;');
	r.push('&lt;/tr&gt;');

	result.getTotalMovesAndPaytable(stepsMap, prizeMap, prizeBoat).forEach(function (item, index) {
		r.push('&lt;tr&gt;');
		r.push('&lt;td class="tablebody" width="23%"&gt;');
		switch (index) {
		case 0:
			r.push(tranMap.row + ' 1');
			break;
		case 1:
			r.push(tranMap.row + ' 2');
			break;
		case 2:
			r.push(tranMap.row + ' 3');
			break;
		case 3:
			r.push(tranMap.row + ' 4');
			break;
		case 4:
			r.push(tranMap.row + ' 5');
			break;
		case 5:
			r.push(tranMap.row + ' 6');
			break;
		default:
			break;
		}
		r.push('&lt;/td&gt;');
		r.push('&lt;td class="tablebody"&gt;');
		r.push(item.steps);
		r.push('&lt;/td&gt;');
		r.push('&lt;td class="tablebody"&gt;');
		r.push(stepsMap[index]);
		r.push('&lt;/td&gt;');
		r.push('&lt;td class="tablebody"&gt;');
		r.push(item.winPrize);
		r.push('&lt;/td&gt;');
		r.push('&lt;/tr&gt;');
	});

	r.push('&lt;/table&gt;');

	r.push('&lt;div width="100%" class="blankStyle"&gt;');
	r.push('&lt;div/&gt;');
	return r.join('');
}
function getScenario(jsonContext) {
	var jsObj = JSON.parse(jsonContext);
	var scenario = jsObj.scenario;
	scenario = scenario.replace(/\0/g, '');
	return scenario;
}
function parsePrizes(prizeNamesDesc, prizeValues) {
	var prizeNames = (prizeNamesDesc.substring(1)).split(',');
	var convertedPrizeValues = (prizeValues.substring(1)).split('|');
	var map = [];
	for (var idx = 0; idx &lt; prizeNames.length; idx++) {
		map[prizeNames[idx]] = convertedPrizeValues[idx];
	}
	return map;
}
function parseTranslations(translationNodeSet) {
	var map = [];
	var list = translationNodeSet.item(0).getChildNodes();
	for (var idx = 1; idx &lt; list.getLength(); idx++) {
		var childNode = list.item(idx);
		if (childNode.name == "phrase") {
			map[childNode.getAttribute("key")] = childNode.getAttribute("value");
		}
	}
	return map;
}
					
				</lxslt:script>
</lxslt:component>
<xsl:template match="root" mode="last">
<table border="0" cellpadding="1" cellspacing="1" width="100%" class="gameDetailsTable">
<tr>
<td valign="top" class="subheader">
<xsl:value-of select="//translation/phrase[@key='totalWager']/@value"/>
<xsl:value-of select="': '"/>
<xsl:call-template name="Utils.ApplyConversionByLocale">
<xsl:with-param name="multi" select="/output/denom/percredit"/>
<xsl:with-param name="value" select="//ResultData/WagerOutcome[@name='Game.Total']/@amount"/>
<xsl:with-param name="code" select="/output/denom/currencycode"/>
<xsl:with-param name="locale" select="//translation/@language"/>
</xsl:call-template>
</td>
</tr>
<tr>
<td valign="top" class="subheader">
<xsl:value-of select="//translation/phrase[@key='totalWins']/@value"/>
<xsl:value-of select="': '"/>
<xsl:call-template name="Utils.ApplyConversionByLocale">
<xsl:with-param name="multi" select="/output/denom/percredit"/>
<xsl:with-param name="value" select="//ResultData/PrizeOutcome[@name='Game.Total']/@totalPay"/>
<xsl:with-param name="code" select="/output/denom/currencycode"/>
<xsl:with-param name="locale" select="//translation/@language"/>
</xsl:call-template>
</td>
</tr>
</table>
</xsl:template>
<xsl:template match="//Outcome">
<xsl:if test="OutcomeDetail/Stage = 'Scenario'">
<xsl:call-template name="History.Detail"/>
</xsl:if>
<xsl:if test="OutcomeDetail/Stage = 'Wager' and OutcomeDetail/NextStage = 'Wager'">
<xsl:call-template name="History.Detail"/>
</xsl:if>
</xsl:template>
<xsl:template name="History.Detail">
<table border="0" cellpadding="0" cellspacing="0" width="100%" class="gameDetailsTable">
<tr>
<td class="tablebold" background="">
<xsl:value-of select="//translation/phrase[@key='transactionId']/@value"/>
<xsl:value-of select="': '"/>
<xsl:value-of select="OutcomeDetail/RngTxnId"/>
</td>
</tr>
</table>
<xsl:variable name="odeResponseJson" select="string(//ResultData/JSONOutcome[@name='ODEResponse']/text())"/>
<xsl:variable name="translations" select="lxslt:nodeset(//translation)"/>
<xsl:variable name="wageredPricePoint" select="string(//ResultData/WagerOutcome[@name='Game.Total']/@amount)"/>
<xsl:variable name="prizeTable" select="lxslt:nodeset(//lottery)"/>
<xsl:variable name="convertedPrizeValues">
<xsl:apply-templates select="//lottery/prizetable/prize" mode="PrizeValue"/>
</xsl:variable>
<xsl:variable name="prizeNames">
<xsl:apply-templates select="//lottery/prizetable/description" mode="PrizeDescriptions"/>
</xsl:variable>
<xsl:value-of select="my-ext:formatJson($odeResponseJson, $translations, string($convertedPrizeValues), string($prizeNames))" disable-output-escaping="yes"/>
</xsl:template>
<xsl:template match="prize" mode="PrizeValue">
<xsl:text>|</xsl:text>
<xsl:call-template name="Utils.ApplyConversionByLocale">
<xsl:with-param name="multi" select="/output/denom/percredit"/>
<xsl:with-param name="value" select="text()"/>
<xsl:with-param name="code" select="/output/denom/currencycode"/>
<xsl:with-param name="locale" select="//translation/@language"/>
</xsl:call-template>
</xsl:template>
<xsl:template match="description" mode="PrizeDescriptions">
<xsl:text>,</xsl:text>
<xsl:value-of select="text()"/>
</xsl:template>
<xsl:template match="text()"/>
</xsl:stylesheet>
