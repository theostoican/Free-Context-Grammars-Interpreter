%{
#include <iostream>
#include <vector>
#include <map>
#include <stdio.h>
#include <set>
#include <algorithm>

#define lastchar yytext[yyleng - 1]

#undef YY_BUF_SIZE

#define YY_BUF_SIZE 66000
%}

%{
bool terminalsSet = false;
char initialSymbol;
std::string secondPart;
char firstPart;
struct alphabet* alphabet;
std::vector<char> nonterminals;

/*
	The first two sets of the grammar
*/
std::set<char> VSet; 
std::set<char> SigmaSet;

std::vector<char> terminals;
std::vector<char> uselessNonterminals;
std::map<char, std::vector<std::string> > rules;
%}

%s VSET VSETSEP ALPHABET ALPHABETSEP RULE1 RULE2 RULEINNERSEP INISYMBOL END RULEOUTERSEP
/* States:
   **VSET: reads the elements that correspond to the V set
   **VSETSEP: reads the separator within the set or the commas that separate two "outer" sets
   **ALPHABET: reads the elements that belong to the alphabet
   **ALPHABETSET: Reads the separators within the alphabet set or those that separate two sets of the grammar
   **RULE1: Reads the left part of a rule
   **RULE2: Reads the right part of a rule
   **RULEINNSERSEP: Reads the separators that can be found within a rule
   **RULEOUTERSEP: Reads the separators that can be found between the rules' set and the initial symbol
   **INISYMBOL: Reads the initial symbol
   **END: Reaches the end of the grammar
 */

letter ([a-d]|[f-z])
special "`"|"-"|"="|"["|"]"|";"|"'"|"\\"|"."|"/"|"~"|"!"|"@"|"#"|"$"|"%"|"^"|"&"|"*"|"_"|"+"|":"|"\""|"|"|"<"|">"|"?"
digit [0-9]
terminal {letter}|{special}|{digit}
nonterminal [A-Z]
spaces [ \t\r\n]


%option noinput
%option nounput
%option noyymore
%option noyywrap

%%

<<EOF>> {return 0;}
<INITIAL>{
 /* At first, read the first bracket of the grammar*/
 	"("{spaces}*"{" BEGIN(VSET);
}
<VSETSEP>{
	"," {
		BEGIN(VSET);
	}
	"}"{spaces}*","{spaces}*"{"{spaces}*"}"{spaces}*","{spaces}*"{"{spaces}*"(" {
		BEGIN(RULE1);
	}
	"}"{spaces}*","{spaces}*"{"{spaces}*"}"{spaces}*","{spaces}*"{"{spaces}*"}"{spaces}*"," {
		BEGIN(INISYMBOL);
	}
	"}"{spaces}*","{spaces}*"{" {
		BEGIN(ALPHABET);
	}
}
<VSET>{
	{terminal} {
		VSet.insert(lastchar);
		BEGIN(VSETSEP);
	}
	{nonterminal} {
		VSet.insert(lastchar);
		nonterminals.push_back(lastchar);
		BEGIN(VSETSEP);
	}
}
<ALPHABET>{
	{terminal} {
		SigmaSet.insert(lastchar);
		terminals.push_back(lastchar);
		BEGIN(ALPHABETSEP);	
	}		
}
<ALPHABETSEP>{
	"," {
		BEGIN(ALPHABET);
	}
	"}"{spaces}*","{spaces}*"{"{spaces}*"}"{spaces}*"," {
		BEGIN(INISYMBOL);
	}
	"}"{spaces}*","{spaces}*"{"{spaces}*"(" {
		BEGIN(RULE1);
	}
}
<RULE1>{
	{nonterminal} {
		firstPart = lastchar;
		BEGIN(RULEINNERSEP);
	}
	{spaces}*"}"{spaces}*"," {
		/*
		* The case when the rules' set is {}
		*/
		BEGIN(INISYMBOL);
	}
}
<RULEINNERSEP>{
	{spaces}*","{spaces}* {
		BEGIN(RULE2);
	}
}
<RULE2>{
	({nonterminal}|{terminal})*|"e" {
		rules[firstPart].push_back(yytext);
		BEGIN(RULEOUTERSEP);
	}
}
<RULEOUTERSEP>{
	{spaces}*")"{spaces}*","{spaces}*"(" {
		BEGIN(RULE1);
	}
	{spaces}*")"{spaces}*"}"{spaces}*"," {
		BEGIN(INISYMBOL);
	}
}
<INISYMBOL>{
	{nonterminal} {
		initialSymbol=lastchar;
		BEGIN(END);
	}
}
<END>{
	")"
}
[ \t\r\n] /*skip whitespace*/
. {
	std::cerr<<"Syntax error"<<std::endl;
	return 1;
}

%%

bool useless_nonterminals()
{
	std::vector<char>::iterator it;
	std::set<char> useful_symbols;
	
	/*
	* We go nonterminals.size() times until we find all possible useful nonterminals
	*/
	for (int cnt = 0; cnt < nonterminals.size(); cnt++)
	{
		for (int i = 0; i < nonterminals.size();i++)
		{

			std::vector<std::string> elem = rules[nonterminals[i]];
			for (int j = 0; j < elem.size(); j++)
			{
				bool isUseful = true;

				for (int k = 0; k < elem[j].size(); k++)
				{
					//the symbol is not "useful"
					if ((elem[j][k] >= 'A' && elem[j][k] <= 'Z') && 
						useful_symbols.find(elem[j][k]) == useful_symbols.end())
					{
						isUseful = false;
						break;
					}
				}
				if (isUseful)
				{
					useful_symbols.insert(nonterminals[i]);
					break;
				}
			}
		}	
	}
	for (int i = 0; i < nonterminals.size(); i++)
	{
		if (useful_symbols.find(nonterminals[i]) == useful_symbols.end())
			{
				uselessNonterminals.push_back(nonterminals[i]);
			}
	}
}

bool has_e()
{
	std::set<char> useless_nonterm_set;
	std::vector<char>::iterator it;

	for (int i = 0; i < uselessNonterminals.size(); i++)
	{
		useless_nonterm_set.insert(uselessNonterminals[i]);
	}
	/*
	*eliminate useless nonterminals from the set V of the grammar
	*/

	for (it = nonterminals.begin(); it != nonterminals.end(); )
	{
		//it's a useless nonterminal
		if (useless_nonterm_set.find(*it) != useless_nonterm_set.end())
		{
			it = nonterminals.erase(it);
		}		
		else
			it++;
	}

	/*
	* Eliminate the rules that correspond to a useless nonterminal
	*/
	for (int i = 0; i < nonterminals.size(); i++)
	{
		std::vector<std::string>::iterator vecit;
		for (vecit = rules[nonterminals[i]].begin(); vecit != rules[nonterminals[i]].end(); )
		{
			bool changed = false;
			std::string rightPart = *vecit;
			for (int j = 0; j < rightPart.size(); j++)
			{
				/*
				* it's a useless nonterminal
				*/
				if (useless_nonterm_set.find(rightPart[j]) != useless_nonterm_set.end())
				{
					changed = true;
					vecit = rules[nonterminals[i]].erase(vecit);
					break;
				}					
			}
			if (!changed) vecit++;
		}
	}

	/*
	* Find nonterminals that can result in empty string
	*/

	std::set<char> empty_string_nonterminals;

	for (int cnt = 0; cnt < nonterminals.size();cnt++)
	{
		for (int i = 0; i < nonterminals.size(); i++)
		{
			std::vector<std::string> vecRightPart = rules[nonterminals[i]];
			/*
			* The right part is the empty string
			*/
			for (int j = 0; j < vecRightPart.size(); j++)
			{
				std::string rightPart = vecRightPart[j];
				bool leads_to_empty = true;
				for (int k = 0; k < rightPart.size(); k++)
				{
					if ((rightPart[k] >= 'A' && rightPart[k] <= 'Z' && empty_string_nonterminals.find(rightPart[k])
						== empty_string_nonterminals.end()) || (!(rightPart[k] >= 'A' && rightPart[k] <= 'Z') && rightPart[k] != 'e'))
						{
							leads_to_empty = false;
							break;
						}
				}
				if (leads_to_empty)
				{
					empty_string_nonterminals.insert(nonterminals[i]);
					break;
				}
			}
		}
	}
	if (empty_string_nonterminals.find(initialSymbol) == empty_string_nonterminals.end())
		return false;
	return true;
}

int main(int argc, char* argv[])
{
	if (argc != 2)
	{
		std::cout<<"Argument error"<<std::endl;
		return 0;
	}
	std::string arg(argv[1]);
	if (arg != "--is-void" && arg != "--has-e" && arg !="--useless-nonterminals")
	{
		std::cerr<<"Argument error"<<std::endl;
		return 0;
	}
    FILE* f = fopen("grammar", "rt"); 
    yyrestart(f);
	
	if(yylex() == 1){
		return 0;
	}

	
	
	/*
		Dealing with semantic errors
	*/
	std::set<char>::iterator it;
	
	//Sigma is included in V
	for (it = SigmaSet.begin(); it != SigmaSet.end(); it++)
	{
		if (VSet.find(*it) == VSet.end())
		{
			std::cerr<<"Semantic error";
			return 0;
		}
	}
	//The set of terminals from V is include in Sigma
	for (it = VSet.begin(); it != VSet.end();it++)
	{
		//it's a terminal symbol
		if (!(*it >= 'A' && *it <= 'Z') && SigmaSet.find(*it) == SigmaSet.end())
		{
			std::cerr<<"Semantic error";
			return 0;
		}
	}
	
	//The initial symbol is included in VSet
	if (VSet.find(initialSymbol) == VSet.end()){
		std::cerr<<"Semantic error";
		return 0;
	}
	
	//Check if left part and right part of a rule belong to VSet
	std::map<char, std::vector<std::string> >::iterator it2;
	for (it2 = rules.begin(); it2 != rules.end(); it2++)
	{
		if (VSet.find(it2->first) == VSet.end())
		{
			std::cerr<<"Semantic error";
			return 0;
		}
		std::vector<std::string> rightPartVec = it2->second;
		for (int j = 0; j < rightPartVec.size(); j++)
		{
			std::string rightPart = rightPartVec[j];
			if (!(rightPart.size()==1 && rightPart[0] == 'e'))
			{
				for (int k = 0; k < rightPart.size(); k++)
				{
					if (VSet.find(rightPart[k]) == VSet.end())
					{
						std::cerr<<"Semantic error";
						return 0;
					}
				}
			}
		}
	}


	/*
	*Find useless nonterminals
	*/
	useless_nonterminals();	

	if (arg == "--useless-nonterminals")
	{
		for (int i = 0; i < uselessNonterminals.size(); i++)
			std::cout<<uselessNonterminals[i]<<std::endl;
	}
	else if (arg == "--has-e")
	{
		bool result = has_e();
		if (result == true)
		{
			std::cout<<"Yes\n";
		}
		else
		{
			std::cout<<"No\n";
		}
	}
	else if (arg == "--is-void")
	{
		if (std::find(uselessNonterminals.begin(),uselessNonterminals.end(), initialSymbol) != uselessNonterminals.end())
		{
			std::cout<<"Yes\n";
		}
		else 
			std::cout<<"No\n";
	}
    fclose(f);

    return 0;
}