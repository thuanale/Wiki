def check_integer(scores):
    if scores != []:
        for x in scores:
            if not isinstance(x,int):
                return False
        return True
    else:
        return False

def latest(scores):
    if check_integer(scores):
        return scores[len(scores)-1]

def personal_best(scores):
    if check_integer(scores):
        sort_scores=scores[:]
        sort_scores.sort(reverse=True)
        return sort_scores[0]

def personal_top_three(scores):
    if check_integer(scores):
        i = 0
        sort_scores=scores[:]
        sort_scores.sort(reverse=True)
        return sort_scores[:3]
    
        
                

scores=[6,1]
print(latest(scores))
print(personal_best(scores))
print(personal_top_three(scores))
