import { useState, useEffect, useCallback } from 'react';
import { commerceService } from '../services/commerceService';

export function useCommerce() {
  const [plans, setPlans] = useState([]);
  const [packages, setPackages] = useState([]);
  const [offers, setOffers] = useState([]);
  const [transactions, setTransactions] = useState([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  const fetchOffers = useCallback(async () => {
    try {
      const res = await commerceService.listOffers();
      setOffers(res.data);
    } catch (err) {
      setError(err.response?.data?.detail || 'Failed to load special offers.');
    }
  }, []);

  const fetchPlans = useCallback(async () => {
    try {
      const res = await commerceService.listPlans();
      setPlans(res.data);
    } catch (err) {
      setError(err.response?.data?.detail || 'Failed to load plans.');
    }
  }, []);

  const fetchPackages = useCallback(async () => {
    try {
      const res = await commerceService.listPackages();
      setPackages(res.data);
    } catch (err) {
      setError(err.response?.data?.detail || 'Failed to load packages.');
    }
  }, []);

  const fetchTransactions = useCallback(async (params) => {
    setLoading(true);
    setError(null);
    try {
      const res = await commerceService.listTransactions(params);
      setTransactions(res.data);
    } catch (err) {
      setError(err.response?.data?.detail || 'Failed to load transactions.');
    } finally {
      setLoading(false);
    }
  }, []);

  const fetchAll = useCallback(async () => {
    setLoading(true);
    await Promise.all([fetchPlans(), fetchPackages(), fetchOffers()]);
    setLoading(false);
  }, [fetchPlans, fetchPackages, fetchOffers]);

  // Plans operations
  const createPlan = useCallback(async (data) => {
    try {
      await commerceService.createPlan(data);
      await fetchPlans();
      return true;
    } catch (err) {
      setError(err.response?.data?.detail || 'Failed to create plan.');
      return false;
    }
  }, [fetchPlans]);

  const updatePlan = useCallback(async (id, data) => {
    try {
      await commerceService.updatePlan(id, data);
      await fetchPlans();
      return true;
    } catch (err) {
      setError(err.response?.data?.detail || 'Failed to update plan.');
      return false;
    }
  }, [fetchPlans]);

  const deletePlan = useCallback(async (id) => {
    try {
      await commerceService.deletePlan(id);
      await fetchPlans();
      return true;
    } catch (err) {
      setError(err.response?.data?.detail || 'Failed to deactivate plan.');
      return false;
    }
  }, [fetchPlans]);

  // Packages operations
  const createPackage = useCallback(async (data) => {
    try {
      await commerceService.createPackage(data);
      await fetchPackages();
      return true;
    } catch (err) {
      setError(err.response?.data?.detail || 'Failed to create package.');
      return false;
    }
  }, [fetchPackages]);

  const updatePackage = useCallback(async (id, data) => {
    try {
      await commerceService.updatePackage(id, data);
      await fetchPackages();
      return true;
    } catch (err) {
      setError(err.response?.data?.detail || 'Failed to update package.');
      return false;
    }
  }, [fetchPackages]);

  // Special Offers operations
  const createOffer = useCallback(async (data) => {
    try {
      await commerceService.createOffer(data);
      await fetchOffers();
      return true;
    } catch (err) {
      setError(err.response?.data?.detail || 'Failed to create special offer.');
      return false;
    }
  }, [fetchOffers]);

  const updateOffer = useCallback(async (id, data) => {
    try {
      await commerceService.updateOffer(id, data);
      await fetchOffers();
      return true;
    } catch (err) {
      setError(err.response?.data?.detail || 'Failed to update special offer.');
      return false;
    }
  }, [fetchOffers]);

  const deleteOffer = useCallback(async (id) => {
    try {
      await commerceService.deleteOffer(id);
      await fetchOffers();
      return true;
    } catch (err) {
      setError(err.response?.data?.detail || 'Failed to delete special offer.');
      return false;
    }
  }, [fetchOffers]);

  useEffect(() => { fetchAll(); }, [fetchAll]);

  return {
    plans, packages, offers, transactions, loading, error,
    createPlan, updatePlan, deletePlan,
    createPackage, updatePackage,
    createOffer, updateOffer, deleteOffer,
    fetchTransactions,
    refresh: fetchAll,
  };
}
