import { useState, useEffect, useCallback } from 'react';
import { contentService } from '../services/contentService';

export function useContent() {
  const [articles, setArticles] = useState([]);
  const [gifts, setGifts] = useState([]);
  const [settings, setSettings] = useState(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  const fetchArticles = useCallback(async () => {
    setLoading(true);
    try {
      const res = await contentService.listArticles();
      setArticles(res.data);
    } catch (err) {
      setError(err.response?.data?.detail || 'Failed to load articles.');
    } finally {
      setLoading(false);
    }
  }, []);

  const fetchGifts = useCallback(async () => {
    setLoading(true);
    try {
      const res = await contentService.listGifts();
      setGifts(res.data);
    } catch (err) {
      setError(err.response?.data?.detail || 'Failed to load virtual gifts.');
    } finally {
      setLoading(false);
    }
  }, []);

  const fetchSettings = useCallback(async () => {
    try {
      const res = await contentService.getSettings();
      setSettings(res.data);
    } catch (err) {
      setError(err.response?.data?.detail || 'Failed to load settings.');
    }
  }, []);

  const createArticle = useCallback(async (data) => {
    try {
      await contentService.createArticle(data);
      await fetchArticles();
      return true;
    } catch (err) {
      setError(err.response?.data?.detail || 'Failed to create article.');
      return false;
    }
  }, [fetchArticles]);

  const updateArticle = useCallback(async (id, data) => {
    try {
      await contentService.updateArticle(id, data);
      await fetchArticles();
      return true;
    } catch (err) {
      setError(err.response?.data?.detail || 'Failed to update article.');
      return false;
    }
  }, [fetchArticles]);

  const deleteArticle = useCallback(async (id) => {
    try {
      await contentService.deleteArticle(id);
      await fetchArticles();
      return true;
    } catch (err) {
      setError(err.response?.data?.detail || 'Failed to delete article.');
      return false;
    }
  }, [fetchArticles]);

  const createGift = useCallback(async (data) => {
    try {
      await contentService.createGift(data);
      await fetchGifts();
      return true;
    } catch (err) {
      setError(err.response?.data?.detail || 'Failed to create gift.');
      return false;
    }
  }, [fetchGifts]);

  const updateGift = useCallback(async (id, data) => {
    try {
      await contentService.updateGift(id, data);
      await fetchGifts();
      return true;
    } catch (err) {
      setError(err.response?.data?.detail || 'Failed to update gift.');
      return false;
    }
  }, [fetchGifts]);

  const deleteGift = useCallback(async (id) => {
    try {
      await contentService.deleteGift(id);
      await fetchGifts();
      return true;
    } catch (err) {
      setError(err.response?.data?.detail || 'Failed to delete gift.');
      return false;
    }
  }, [fetchGifts]);

  const saveSettings = useCallback(async (data) => {
    try {
      const res = await contentService.updateSettings(data);
      setSettings(res.data);
      return true;
    } catch (err) {
      setError(err.response?.data?.detail || 'Failed to save settings.');
      return false;
    }
  }, []);

  useEffect(() => { fetchArticles(); fetchGifts(); fetchSettings(); }, [fetchArticles, fetchGifts, fetchSettings]);

  return {
    articles, gifts, settings, loading, error,
    createArticle, updateArticle, deleteArticle,
    createGift, updateGift, deleteGift, fetchGifts,
    saveSettings, fetchSettings,
  };
}
