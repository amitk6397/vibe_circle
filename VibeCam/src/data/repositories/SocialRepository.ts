import { Community, Person, Post } from '../../types';

export interface SocialRepository {
  getPeople(): Promise<Person[]>;
  getCommunities(): Promise<Community[]>;
  getFeed(): Promise<Post[]>;
  searchPeople(query: string): Promise<Person[]>;
}
