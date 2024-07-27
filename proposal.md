# Foundation Mission (RFP) Application
Please verify that you meet the qualifications for submitting at the above Tier


### What makes your Alliance best-suited to execute this Mission?

Our Alliance is exceptionally well-suited to execute this Mission due to the diverse and complementary expertise of its members. Yang, a PhD candidate in statistics at the University of Hong Kong, brings deep knowledge in the theory and application of complex networks and statistical modeling, providing a strong foundation for data analysis and network-based insights. Ma, also a PhD candidate at the University of Hong Kong's faculty of Engineering, contributes his expertise in system analysis from an engineering perspective, ensuring robust and efficient system designs and solutions. Bai, a skilled quantitative analyst with five years of experience in quantitative research and data science, adds his proficiency in Python, R, SQL, and blockchain technologies. His professional background in developing quantitative models, risk metrics, and stress testing, combined with active participation in Ethereum collaborative research initiatives, strengthens our capacity for sophisticated financial and technological analysis. Together, our team’s blend of theoretical knowledge, practical experience, and interdisciplinary skills make us uniquely equipped to tackle the complexities of this Mission.

### Please describe your proposed solution based on the above Solution Criteria (if applicable):

The Voting Influence and Concentration Analysis (VICA) is a systematic approach to estimating the voting bloc's marginal influence on voting outcomes and measuring the degree of concentration in the voting system. This method, specifically tailored for the Optimism Collective, leverages logistic regression, counterfactual analysis, and data augmentation to deliver a robust and comprehensive understanding of each voting bloc's explicit and implicit influence on the voting process. The method includes two parts:

Part 1: Estimate Each Voting Bloc's Explicit and Implicit Influence on Voting Outcomes:
Voters are grouped into voting blocs by network analysis of on-chain activities and off-chain social media graphs. A voting bloc may include members from both houses and Councils. Logistic regression is employed to analyze each Voting Bloc's explicit marginal effect on voting outcomes. Next, the data is reversed by assuming each voting bloc's vote is the opposite of their actual vote, and logistic regression is performed again. We can estimate each voting bloc's implicit (counterfactual) marginal effect by comparing the regression results before and after reversing. Additionally, separate logistic regressions are conducted for the Token House and Citizen’s House to estimate each voting bloc's effect in different houses. The data from both houses is then merged to build a combined regression model, allowing us to estimate each voting bloc's overall effect on the entire voting system.

Part 2: Construct the Concentration Metric Based on Estimated Effects:
Based on the estimated effects, the voting power distribution in both houses and the overall system can be observed. Statistical properties of the distribution including standard deviation and variance, kurtosis, and skewness will be calculated. Considering the statistical properties, we will compare various concentration metrics, including the Gini Coefficient, Herfindahl-Hirschman Index, and Entropy, to select the most appropriate one.

### Please outline your step-by-step plan to execute this Mission, including expected deadlines to complete each peice of work:

Week 1-4: Data Collection/Preprocessing, Network Analysis and Clustering
Week 4-6: Voting Bloc's Explicit and Implicit Influence Estimation
Week 6-8: Concentration Metric Construction and Validation
Week 8-12: Dashboard Development and Release

### Please define the critical milestone(s) that should be used to determine whether you’ve executed on this proposal:

1. Research and planning
The result of network analysis/clustering, voting bloc's explicit/implicit Influence distribution and selected concentration metric will be presented to the Mission Request authors for feedback. 

2. Prototype development and testing
A Python implemented prototype will be delivered for testing with real and dummy data.

3. Production development
A Python or Dune dashboard will be delivered for public use.

### Please list any additional support your team would require to execute this mission (financial, technical, etc.):

Ongoing communication with the Optimism team is needed to better understand the community social graph, Citizen House functionality and selection rules, and future governance planning.

### Grants are awarded in OP, locked for one year. Please let us know if access to upfront capital is a barrier to completing your Mission and you would like to be considered for a small upfront cash grant: (Note: there is no guarantee that approved Missions will receive up-front cash grants.)

N/A

### Please check the following to make sure you understand the terms of the Optimism Foundation RFP program:

- [x] I understand my grant for completing this RFP will be locked for one year from the date of proposal acceptance.
- [x] I understand that I will be required to provide additional KYC information to the Optimism Foundation to receive this grant
- [x] I understand my locked grant may be clawed back for failure to execute on critical milestones, as outlined in the Operating Manual
- [x] I confirm that I have read and understand the grant policies
- [x] I understand that I will be expected to following the public grant reporting requirements outlined here
-- end of application --
