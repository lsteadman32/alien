class_name  Fuzzy

static func score_match(q: String, cand: String) -> float:
	if q == cand:
		return 1.0
	if cand.begins_with(q):
		return 0.9
	if cand.contains(q):
		return 0.8
	return q.similarity(cand) * 0.7

static func best_match(query: String, candidates: Array, threshold: float = 0.4) -> String:
	var q := query.strip_edges().to_lower()
	if q == "":
		return ""
	var best := ""
	var best_score: = 0.0
	for c in candidates:
		var s := score_match(q, str(c).to_lower())
		if s > best_score:
			best_score = s
			best = str(c)
	return best if best_score >= threshold else ""
