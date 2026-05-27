const session = require('express-session');
const { supabaseAdmin } = require('./supabase');

class SupabaseStore extends session.Store {
  constructor() {
    super();
  }

  async get(sid, cb) {
    try {
      const { data, error } = await supabaseAdmin
        .from('sessions')
        .select('sess')
        .eq('sid', sid)
        .single();
        
      if (error || !data) return cb(null, null);
      return cb(null, data.sess);
    } catch (e) {
      return cb(e);
    }
  }

  async set(sid, sess, cb) {
    try {
      let expire;
      if (sess.cookie && sess.cookie.expires) {
        expire = new Date(sess.cookie.expires).toISOString();
      } else {
        const d = new Date();
        d.setDate(d.getDate() + 1);
        expire = d.toISOString();
      }

      await supabaseAdmin
        .from('sessions')
        .upsert({ sid, sess, expire });
        
      if (cb) cb(null);
    } catch (e) {
      if (cb) cb(e);
    }
  }

  async destroy(sid, cb) {
    try {
      await supabaseAdmin
        .from('sessions')
        .delete()
        .eq('sid', sid);
        
      if (cb) cb(null);
    } catch (e) {
      if (cb) cb(e);
    }
  }
}

module.exports = SupabaseStore;
