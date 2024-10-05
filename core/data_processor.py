import numpy as np
import pandas as pd
import requests


def process_token_house_data():
    # Token House Data
    # read data
    df_proposals_votes = pd.read_csv(
        "./raw_data/2024-07-01_optimism_proposals_votes.csv")
    # unify proposal_id to hexdecimal
    df_proposals_votes.proposal_id = df_proposals_votes.proposal_id.apply(
        lambda x: str(hex(int(x[18:]))) if 'Proposal|Proposal|' in x else x)
    # fill na otherwise groupby will drop rows
    df_proposals_votes = df_proposals_votes.fillna('N/A')

    df_onchain = df_proposals_votes.query(
        'vote_type == "ON_CHAIN"').reset_index(drop=True)

    # Step 1: Sort the DataFrame by 'proposal_id' and 'voting_power' in descending order
    df_sorted = df_onchain.sort_values(
        by=['proposal_id', 'voting_power'], ascending=[True, False])

    # Step 2: Group by 'proposal_id' and select the top 200 for each group
    df_top_200_onchain = df_sorted.groupby(
        'proposal_id').head(200).reset_index(drop=True)
    return df_proposals_votes, df_top_200_onchain


def process_citizen_house_data():
    # Citizen House Data
    # df_citizen_snapshot_proposal = pd.read_json('citizen_snapshot_proposals.json')

    url = "https://hub.snapshot.org/graphql?operationName=Proposals&query=query%20Proposals%20%7B%0A%20%20proposals%20(%0A%20%20%20%20first%3A%20100%2C%0A%20%20%20%20skip%3A%200%2C%0A%20%20%20%20where%3A%20%7B%0A%20%20%20%20%20%20space_in%3A%20%5B%22citizenshouse.eth%22%5D%2C%0A%20%20%20%20%20%20state%3A%20%22closed%22%0A%20%20%20%20%7D%2C%0A%20%20%20%20orderBy%3A%20%22created%22%2C%0A%20%20%20%20orderDirection%3A%20desc%0A%20%20)%20%7B%0A%20%20%20%20id%0A%20%20%20%20title%0A%20%20%20%20body%0A%20%20%20%20choices%0A%20%20%20%20start%0A%20%20%20%20end%0A%20%20%20%20snapshot%0A%20%20%20%20state%0A%20%20%20%20author%0A%20%20%20%20space%20%7B%0A%20%20%20%20%20%20id%0A%20%20%20%20%20%20name%0A%20%20%20%20%7D%0A%20%20%7D%0A%7D"
    response = requests.get(url)
    df_citizen_snapshot_proposal = pd.DataFrame(
        response.json()['data']['proposals'])
    df_citizen_snapshot_proposal = df_citizen_snapshot_proposal.rename(columns={
        'id': 'proposal_id'})

    df_citizen_snapshot_proposal_votes = pd.DataFrame()

    for id in df_citizen_snapshot_proposal.proposal_id.to_list():
        url = f"""https://hub.snapshot.org/graphql?operationName=Votes&query=query%20Votes%20%7B%0A%20%20votes%20(%0A%20%20%20%20first%3A%201000%0A%20%20%20%20skip%3A%200%0A%20%20%20%20where%3A%20%7B%0A%20%20%20%20%20%20proposal%3A%20%22{
            id}%22%0A%20%20%20%20%7D%0A%20%20%20%20orderBy%3A%20%22created%22%2C%0A%20%20%20%20orderDirection%3A%20desc%0A%20%20)%20%7B%0A%20%20%20%20id%0A%20%20%20%20voter%0A%20%20%20%20created%0A%20%20%20%20proposal%20%7B%0A%20%20%20%20%20%20id%0A%20%20%20%20%7D%0A%20%20%20%20choice%0A%20%20%20%20space%20%7B%0A%20%20%20%20%20%20id%0A%20%20%20%20%7D%0A%20%20%7D%0A%7D%0A"""
        response = requests.get(url)
        temp = response.json()['data']['votes']
        for t in range(len(temp)):
            temp[t]['proposal_id'] = temp[t]['proposal']['id']
            temp[t]['space_id'] = temp[t]['space']['id']
        temp_df = pd.DataFrame(temp)
        df_citizen_snapshot_proposal_votes = pd.concat(
            [df_citizen_snapshot_proposal_votes, temp_df])

    df_citizen_snapshot_proposal_votes = pd.merge(
        df_citizen_snapshot_proposal_votes, df_citizen_snapshot_proposal, how="left", on='proposal_id')

    df_citizen_snapshot_proposal_votes['voted_choice'] = df_citizen_snapshot_proposal_votes.apply(
        lambda row: row['choices'][row['choice']-1], axis=1)
    df_citizen_snapshot_proposal_votes['voting_power'] = 1
    df_citizen_snapshot_proposal_votes['vote_type'] = 'citizen_house'
    df_citizen_snapshot_proposal_votes = df_citizen_snapshot_proposal_votes.rename(
        columns={'voter': 'address'})
    df_citizen_snapshot_proposal_votes['address'] = df_citizen_snapshot_proposal_votes['address'].str.lower(
    )
    return df_citizen_snapshot_proposal_votes


def combined_data(df_proposals_votes, df_citizen_snapshot_proposal_votes):
    # Combined Data
    df_summary = df_proposals_votes[[
        'vote_type', 'proposal_id', 'title', 'voted_choice', 'voting_power']].copy()
    df_summary = df_summary[df_summary['vote_type'] == 'ON_CHAIN']
    df_summary['vote_type'] = 'token_house'

    df_summary = pd.concat([df_summary, df_citizen_snapshot_proposal_votes[[
        'vote_type', 'proposal_id', 'title', 'voted_choice', 'voting_power']]], ignore_index=True)

    df_summary = df_summary.groupby(
        ['vote_type', 'proposal_id', 'title', 'voted_choice'], as_index=False).sum()

    df_summary = df_summary.sort_values(
        by=['vote_type', 'proposal_id', 'voting_power'], ascending=[True, True, False])

    df_summary = df_summary.reset_index(drop=True)
    return df_summary
