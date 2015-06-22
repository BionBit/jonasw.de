---
title: Demonstrating Manipulability of Voting Procedures
categories: [Javascript]
date: 2014-08-25 09:40:00
published: false
---

In this post I will show that popular voting procedures are manipulable.
The code below shows that four procedures depicted below can be made to yield
four different winners given the same configuration.

## Description of the used Voting Procedures

Firstly, a few commonly used terms are defined. After that
four very different voting procedures and their properties are introduced here.

### Preference Relation

Coming from mathematics, a preference relation gives an ordering between elements
by peference.

### Plurality Method

The plurality method is the easiest of the discussed procedures.
The winner is simply the candidate which most of the voters
ranked highest in their preferences.



var _ = require('underscore');

var preferences = [
	'ABCD',
	'ABCD',
	'ABCD',
	'ABCD'
];

function usingPosition(pos) {
	return function (c) {
		return c[pos];
	};
}

function topCounts(preferences) {
	return _.pairs(_.countBy(preferences, usingPosition(0)));
}

function lowCounts(preferences) {
	return _.pairs(_.countBy(preferences, function (c) { return c[c.length - 1]; }));
}

function clone(x) {
	return JSON.parse(JSON.stringify(x));
}
function haveMoreThanOneCandidates(x) {
	var found = {};
	_.each(x, function (r) {
		_.each(r, function (c) {
			found[c] = 1;
		})
	});
	
	return _.keys(found).length > 1;
}

function eliminateHimIn(kicked, mm) {
	_.each(mm, function (row) {
		row.splice(row.indexOf(kicked), 1);
	});
}

// VOTING PROCEDURES

function pluralityWinner(preferences) {
	return _.max(topCounts(preferences), usingPosition(1))[0];
}

function instantRunoff(preferences) {
	var mm = clone(preferences);
	while (haveMoreThanOneCandidates(mm)) {
		var runOff = _.min(topCounts(mm), usingPosition(1))[0];
		eliminateHimIn(runOff[0], mm);
	}
	return mm[0][0];
}

function coombsMethod(preferences) {
	var mm = clone(preferences);
	while (haveMoreThanOneCandidates(mm)) {
		var kicked = _.max(lowCounts(mm), usingPosition(1))[0];
		eliminateHimIn(kicked[0], mm);
	}
	return mm[0][0];
}

function bordaCount(preferences) {
	var points = {};
	_.each(preferences, function (row) {
		_.each(row, function (candidate, idx) {
			var awardedPoints = row.length - (idx + 1);
			if (points[candidate]) {
				points[candidate] += awardedPoints;
			} else {
				points[candidate] = awardedPoints;
			}
		});
	});
	return _.max(_.pairs(points), usingPosition(1))[0];
}


function checkPointsFor(prepared_prefs) {
	var results = [pluralityWinner(prepared_prefs), instantRunoff(prepared_prefs), coombsMethod(prepared_prefs), bordaCount(prepared_prefs)];
	var isOk = results.length == _.uniq(results).length;
	return isOk;
}


var counter = 0;
var prepared_prefs = _.map(preferences, function (row) { return row.split(''); });
do {
	prepared_prefs = _.map(prepared_prefs, function (row) {
		return _.shuffle(row);
	});
	counter++;
} while (!checkPointsFor(prepared_prefs));

console.log(prepared_prefs);
console.log(checkPointsFor(prepared_prefs));
console.log('Took ' + counter + ' tries.');

console.log('');
_.each(prepared_prefs, function (row, idx) {
	console.log(row.join(' \\prec_' + (idx + 1))+ ' ');
});
